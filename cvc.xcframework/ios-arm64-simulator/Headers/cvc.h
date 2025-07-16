//
// Created by Peter Paravinja on 11. 7. 25.
//
#ifndef CVC_UMBRELLA_H
#define CVC_UMBRELLA_H

// Import main CVC headers
#include "crypto.h"
#include "core.h"

// ECDH headers
#include "ecdh_Ed25519.h"
#include "ecdh_NIST256.h"

// ECP headers
#include "ecp_Ed25519.h"
#include "ecp_NIST256.h"

// EDDSA headers
#include "eddsa_Ed25519.h"
#include "eddsa_NIST256.h"

// JWT headers
#include "l8w8jwt/encode.h"
#include "l8w8jwt/decode.h"
#include "l8w8jwt/algs.h"

#endif /* CVC_UMBRELLA_H */