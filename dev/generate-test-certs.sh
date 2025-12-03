#!/bin/bash
##
## This source file is part of the valkey-swift project
## Copyright (c) 2025 the valkey-swift project authors
##
## See LICENSE.txt for license information
## SPDX-License-Identifier: Apache-2.0
##

# This is a copy of the gen-test-certs.sh script from https://github/valkey-io/valkey
# BSD 3-Clause License
#
# Copyright (c) 2024-present, Valkey contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#     * Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Generate some test certificates which are used by the regression test suite:
#
#   valkey/certs/ca.{crt,key}          Self signed CA certificate.
#   valkey/certs/client.{crt,key}      A certificate restricted for SSL client usage.
#   valkey/certs/server.{crt,key}      A certificate restricted for SSL server usage.
#   valkey/certs/valkey.dh              DH Params file.

generate_cert() {
    local name=$1
    local cn="$2"
    local opts="$3"

    local keyfile=valkey/certs/${name}.key
    local certfile=valkey/certs/${name}.crt

    [ -f "$keyfile" ] || openssl genrsa -out "$keyfile" 2048
    openssl req \
        -new -sha256 \
        -subj "/O=Valkey Test/CN=$cn" \
        -key "$keyfile" | \
        openssl x509 \
            -req -sha256 \
            -CA valkey/certs/ca.crt \
            -CAkey valkey/certs/ca.key \
            -CAserial valkey/certs/ca.txt \
            -CAcreateserial \
            -days 365 \
            ${opts[@]} \
            -out "$certfile"
    chmod a+r "$keyfile"
}

mkdir -p valkey/certs
[ -f valkey/certs/ca.key ] || openssl genrsa -out valkey/certs/ca.key 4096
openssl req \
    -x509 -new -nodes -sha256 \
    -key valkey/certs/ca.key \
    -days 3650 \
    -subj '/O=Valkey Test/CN=Certificate Authority' \
    -out valkey/certs/ca.crt

cat > valkey/certs/openssl.cnf <<_END_
[ server_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = server

[ client_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = client
_END_

generate_cert server "Server-only" "-extfile valkey/certs/openssl.cnf -extensions server_cert"
generate_cert client "Client-only" "-extfile valkey/certs/openssl.cnf -extensions client_cert"
