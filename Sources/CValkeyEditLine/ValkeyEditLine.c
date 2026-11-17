//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#include "CValkeyEditLine.h"
#include <stdlib.h>

char* valkeyPrompt(EditLine *e) {
    return "> ";
}

/*
 * Create valkey line editor
 */
ValkeyEditLine* editLineCreate() {
    ValkeyEditLine* editLine = (ValkeyEditLine*)malloc(sizeof(ValkeyEditLine));
    editLine->el = el_init("ValkeyCLI", stdin, stdout, stderr);
    el_set(editLine->el, EL_PROMPT, &valkeyPrompt);
    el_set(editLine->el, EL_EDITOR, "emacs");
    el_set(editLine->el, EL_SIGNAL, 1);
    
    // With support for history
    editLine->history = history_init();
    history(editLine->history, &editLine->event, H_SETSIZE, 800);
    el_set(editLine->el, EL_HIST, history, editLine->history);
    return editLine;
}

/*
 * Destroy valkey line editor
 */
void editLineDestroy(ValkeyEditLine* editLine) {
    history_end(editLine->history);
    el_end(editLine->el);
    free(editLine);
}

/*
 * Get line from valkey line editor
 */
const char* editLineGetLine(ValkeyEditLine* editLine) {
    int count;
    const char* line = el_gets(editLine->el, &count);
    
    if (count > 0) {
        // only record history if line is more than just a new line
        if (count > 1) {
            history(editLine->history, &editLine->event, H_ENTER, line);
        }
        return line;
    }
    return NULL;
}