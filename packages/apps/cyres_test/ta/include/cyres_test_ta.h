/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
#ifndef _CYRES_TEST_TA_H_
#define _CYRES_TEST_TA_H_

// EF484CBB-E6B5-4667-95A3-173D2C883FF5
#define TA_CYRES_TEST_UUID { 0xef484cbb, 0xe6b5, 0x4667, \
		 { 0x95, 0xa3, 0x17, 0x3d, 0x2c, 0x88, 0x3f, 0xf5 } }

enum TA_CYRES_TEST_CMDS {
	TA_CYRES_TEST_GET_PRIVATE_KEY,
	TA_CYRES_TEST_GET_PUBLIC_KEY,
	TA_CYRES_TEST_GET_CERT_CHAIN,
	TA_CYRES_TEST_GET_SEAL_KEY,
};

#endif /* _CYRES_TEST_TA_H_ */
