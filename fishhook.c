#include "fishhook.h"
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include <mach-o/loader.h>

struct rebindings_entry { struct rebinding *rebindings; size_t rebindings_nel; struct rebindings_entry *next; };
static struct rebindings_entry *_rebindings_head;

static int prepend_rebindings(struct rebindings_entry **rebindings_head, struct rebinding rebindings[], size_t nel) {
  struct rebindings_entry *new_entry = (struct rebindings_entry *) malloc(sizeof(struct rebindings_entry));
  if (!new_entry) return -1;
  new_entry->rebindings = (struct rebinding *) malloc(sizeof(struct rebinding) * nel);
  if (!new_entry->rebindings) { free(new_entry); return -1; }
  memcpy(new_entry->rebindings, rebindings, sizeof(struct rebinding) * nel);
  new_entry->rebindings_nel = nel;
  new_entry->next = *rebindings_head;
  *rebindings_head = new_entry;
  return 0;
}

static void perform_rebinding_with_section(struct rebindings_entry *rebindings, struct section_64 *section, intptr_t slide, struct nlist_64 *symtab, char *strtab, uint32_t *indirect_symtab) {
  uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;
  void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);
  for (uint i = 0; i < section->size / sizeof(void *); i++) {
    uint32_t symtab_index = indirect_symbol_indices[i];
    if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL || symtab_index == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) continue;
    uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
    char *symbol_name = strtab + strtab_offset;
    struct rebindings_entry *cur = rebindings;
    while (cur) {
      for (uint j = 0; j < cur->rebindings_nel; j++) {
        if (strcmp(&symbol_name[1], cur->rebindings[j].name) == 0) {
          if (cur->rebindings[j].replaced != NULL && indirect_symbol_bindings[i] != cur->rebindings[j].replacement) {
            *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i];
          }
          indirect_symbol_bindings[i] = cur->rebindings[j].replacement;
          goto symbol_loop;
        }
      }
      cur = cur->next;
    }
  symbol_loop:;
  }
}

static void rebind_symbols_for_image(struct rebindings_entry *rebindings, const struct mach_header_64 *header, intptr_t slide) {
  if (header->magic != MH_MAGIC_64) return;
  uintptr_t cur = (uintptr_t)header + sizeof(struct mach_header_64);
  struct symtab_command *symtab_cmd = NULL;
  struct dysymtab_command *dysymtab_cmd = NULL;
  struct segment_command_64 *linkedit_segment = NULL;
  for (uint i = 0; i < header->ncmds; i++, cur += ((struct load_command *)cur)->cmdsize) {
    struct load_command *lc = (struct load_command *)cur;
    if (lc->cmd == LC_SYMTAB) symtab_cmd = (struct symtab_command *)lc;
    else if (lc->cmd == LC_DYSYMTAB) dysymtab_cmd = (struct dysymtab_command *)lc;
    else if (lc->cmd == LC_SEGMENT_64 && strcmp(((struct segment_command_64 *)lc)->segname, SEG_LINKEDIT) == 0) linkedit_segment = (struct segment_command_64 *)lc;
  }
  if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment || !dysymtab_cmd->nindirectsyms) return;
  uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
  struct nlist_64 *symtab = (struct nlist_64 *)(linkedit_base + symtab_cmd->symoff);
  char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);
  uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);
  cur = (uintptr_t)header + sizeof(struct mach_header_64);
  for (uint i = 0; i < header->ncmds; i++, cur += ((struct load_command *)cur)->cmdsize) {
    struct load_command *lc = (struct load_command *)cur;
    if (lc->cmd == LC_SEGMENT_64) {
      struct segment_command_64 *seg = (struct segment_command_64 *)lc;
      struct section_64 *sect = (struct section_64 *)(seg + 1);
      for (uint j = 0; j < seg->nsects; j++, sect++) {
        if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS || (sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
          perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab);
        }
      }
    }
  }
}

static void _rebind_symbols_for_image(const struct mach_header *header, intptr_t slide) {
  rebind_symbols_for_image(_rebindings_head, (const struct mach_header_64 *)header, slide);
}

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel) {
  int retval = prepend_rebindings(&_rebindings_head, rebindings, rebindings_nel);
  if (retval < 0) return retval;
  if (!_rebindings_head->next) _dyld_register_func_for_add_image(_rebind_symbols_for_image);
  else {
    uint32_t c = _dyld_image_count();
    for (uint32_t i = 0; i < c; i++) _rebind_symbols_for_image(_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
  }
  return 0;
}
