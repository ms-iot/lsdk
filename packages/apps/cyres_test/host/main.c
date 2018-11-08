/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */

#include <err.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

/* OP-TEE TEE client API (built by optee_client) */
#include <tee_client_api.h>

/* To get the UUID (found the the TA's h-file(s)) */
#include <cyres_test_ta.h>

static const char *str_from_origin(uint32_t origin)
{
	switch (origin) {
	case TEEC_ORIGIN_API: return "API";
	case TEEC_ORIGIN_COMMS: return "COMMS";
	case TEEC_ORIGIN_TEE: return "TEE";
	case TEEC_ORIGIN_TRUSTED_APP: return "TA";
	}
	return "[unknown origin]";
}

static const char *str_from_res(TEEC_Result res)
{
	switch (res) {
	case TEEC_SUCCESS: return "TEEC_SUCCESS";
	case TEEC_ERROR_GENERIC: return "TEEC_ERROR_GENERIC";
	case TEEC_ERROR_ACCESS_DENIED: return "TEEC_ERROR_ACCESS_DENIED";
	case TEEC_ERROR_CANCEL: return "TEEC_ERROR_CANCEL";
	case TEEC_ERROR_ACCESS_CONFLICT: return "TEEC_ERROR_ACCESS_CONFLICT";
	case TEEC_ERROR_EXCESS_DATA: return "TEEC_ERROR_EXCESS_DATA";
	case TEEC_ERROR_BAD_FORMAT: return "TEEC_ERROR_BAD_FORMAT";
	case TEEC_ERROR_BAD_PARAMETERS: return "TEEC_ERROR_BAD_PARAMETERS";
	case TEEC_ERROR_BAD_STATE: return "TEEC_ERROR_BAD_STATE";
	case TEEC_ERROR_ITEM_NOT_FOUND: return "TEEC_ERROR_ITEM_NOT_FOUND";
	case TEEC_ERROR_NOT_IMPLEMENTED: return "TEEC_ERROR_NOT_IMPLEMENTED";
	case TEEC_ERROR_NOT_SUPPORTED: return "TEEC_ERROR_NOT_SUPPORTED";
	case TEEC_ERROR_NO_DATA: return "TEEC_ERROR_NO_DATA";
	case TEEC_ERROR_OUT_OF_MEMORY: return "TEEC_ERROR_OUT_OF_MEMORY";
	case TEEC_ERROR_BUSY: return "TEEC_ERROR_BUSY";
	case TEEC_ERROR_COMMUNICATION: return "TEEC_ERROR_COMMUNICATION";
	case TEEC_ERROR_SECURITY: return "TEEC_ERROR_SECURITY";
	case TEEC_ERROR_SHORT_BUFFER: return "TEEC_ERROR_SHORT_BUFFER";
	case TEEC_ERROR_EXTERNAL_CANCEL: return "TEEC_ERROR_EXTERNAL_CANCEL";
	case TEEC_ERROR_TARGET_DEAD: return "TEEC_ERROR_TARGET_DEAD";
	}

	return "[unknown error]";
}

int query_string_from_ta(TEEC_Session *sess, uint32_t commandID, char **str)
{
	TEEC_Result res;
	TEEC_Operation op;
	char *buf = NULL;
	uint32_t err_origin;

	/* get required buffer size */
	memset(&op, 0, sizeof(op));
	op.paramTypes = TEEC_PARAM_TYPES(TEEC_MEMREF_TEMP_OUTPUT, TEEC_NONE,
					 TEEC_NONE, TEEC_NONE);

	res = TEEC_InvokeCommand(sess, commandID, &op, &err_origin);
	if (res != TEEC_ERROR_SHORT_BUFFER) {
		fprintf(stderr,
			"TEEC_InvokeCommand failed with code 0x%x (%s)"
			"origin %s\n",
			res, str_from_res(res), str_from_origin(err_origin));
		goto end;
	}

	/* allocate buffer to hold string */
	buf = (char *)malloc(op.params[0].tmpref.size);
	if (!buf) {
		res = -ENOMEM;
		fprintf(stderr, "Allocation of %d bytes failed\n",
			op.params[0].value.a);
		goto end;
	}

	/* retrieve string */
	op.params[0].tmpref.buffer = buf;
	res = TEEC_InvokeCommand(sess, commandID, &op, &err_origin);
	if (res != TEEC_SUCCESS) {
		fprintf(stderr,
			"TEEC_InvokeCommand failed with code 0x%x (%s)"
			"origin %s\n",
			res, str_from_res(res), str_from_origin(err_origin));
		goto end;
	}

	*str = buf;
end:
	if (res)
		if (buf)
			free(buf);

	return res;
}

void query_and_print_string(TEEC_Session *sess, uint32_t commandID)
{
	int res;
	char *str = NULL;

	res = query_string_from_ta(sess, commandID, &str);
	if (res) {
		fprintf(stderr, "Failed to get string from TA\n");
		goto end;
	}

	printf("string (length %ld):\n%s\n", strlen(str), str);

end:
	if (str)
		free(str);
}

void test_get_private_key(TEEC_Session *sess)
{
	printf("Testing PTA_CYRES_GET_PRIVATE_KEY\n");
	query_and_print_string(sess, TA_CYRES_TEST_GET_PRIVATE_KEY);
}

void test_get_public_key(TEEC_Session *sess)
{
	printf("Testing PTA_CYRES_GET_PUBLIC_KEY\n");
	query_and_print_string(sess, TA_CYRES_TEST_GET_PUBLIC_KEY);
}

void test_get_cert_chain(TEEC_Session *sess)
{
	printf("Testing PTA_CYRES_GET_CERT_CHAIN\n");
	query_and_print_string(sess, TA_CYRES_TEST_GET_CERT_CHAIN);
}

void test_get_seal_key(TEEC_Session *sess)
{
	TEEC_Result res;
	TEEC_Operation op;
	uint32_t err_origin;
	uint32_t seal_key[8];

	printf("Testing PTA_CYRES_GET_SEAL_KEY\n");

	memset(&op, 0, sizeof(op));
	op.paramTypes = TEEC_PARAM_TYPES(TEEC_MEMREF_TEMP_OUTPUT,
					 TEEC_MEMREF_TEMP_INPUT,
					 TEEC_NONE, TEEC_NONE);

	op.params[0].tmpref.buffer = &seal_key;
	op.params[0].tmpref.size = sizeof(seal_key);

	/* 2nd parameter is optional, leave it NULL */

	res = TEEC_InvokeCommand(sess, TA_CYRES_TEST_GET_SEAL_KEY, &op,
				 &err_origin);
	if (res != TEEC_SUCCESS) {
		fprintf(stderr,
			"TEEC_InvokeCommand failed with code 0x%x (%s)"
			"origin %s\n",
			res, str_from_res(res), str_from_origin(err_origin));
		goto end;
	}

	printf("Seal key:\n"
	       "0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x\n",
		seal_key[0],
		seal_key[1],
		seal_key[2],
		seal_key[3],
		seal_key[4],
		seal_key[5],
		seal_key[6],
		seal_key[7]);

end:
	return;
}

int main(void)
{
	TEEC_Result res;
	TEEC_Context ctx;
	TEEC_Session sess;
	TEEC_UUID uuid = TA_CYRES_TEST_UUID;
	uint32_t err_origin;

	printf("Running basic cyres sanity tests\n");

	/* Initialize a context connecting us to the TEE */
	res = TEEC_InitializeContext(NULL, &ctx);
	if (res != TEEC_SUCCESS) {
		fprintf(stderr, "TEEC_InitializeContext failed with "
			"code 0x%x (%s)\n",
			res, str_from_res(res));
		return 1;
	}

	res = TEEC_OpenSession(&ctx, &sess, &uuid,
			       TEEC_LOGIN_PUBLIC, NULL, NULL, &err_origin);
	if (res != TEEC_SUCCESS) {
		fprintf(stderr,
			"TEEC_Opensession failed with code 0x%x (%s) "
			"origin %s\n",
			res, str_from_res(res), str_from_origin(err_origin));
		return 1;
	}

	test_get_private_key(&sess);
	test_get_public_key(&sess);
	test_get_cert_chain(&sess);
	//test_get_seal_key(&sess);

	TEEC_CloseSession(&sess);
	TEEC_FinalizeContext(&ctx);

	return 0;
}
