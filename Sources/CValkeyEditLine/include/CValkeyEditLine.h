//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

#include <histedit.h>

// Valkey line editor
typedef struct ValkeyEditLine {
    EditLine* el;
    History* history;
    HistEvent event;
} ValkeyEditLine;

// Create Valkey line editor
ValkeyEditLine* editLineCreate();
// Destroy Valkey line editor
void editLineDestroy(ValkeyEditLine* editLine);
// Get line from Valkey line editor
const char* editLineGetLine(ValkeyEditLine* editLine);