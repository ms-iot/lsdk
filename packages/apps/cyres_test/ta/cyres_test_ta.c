/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */

#include <tee_internal_api.h>
#include <tee_internal_api_extensions.h>
#include <pta_cyres.h>
#include <string.h>

#include <cyres_test_ta.h>

#pragma GCC diagnostic ignored "-Wpedantic"
#pragma GCC diagnostic ignored "-Wenum-compare"
_Static_assert(
	PTA_CYRES_GET_PRIVATE_KEY == TA_CYRES_TEST_GET_PRIVATE_KEY,
	"Incorrect command value");
_Static_assert(
	PTA_CYRES_GET_PUBLIC_KEY == TA_CYRES_TEST_GET_PUBLIC_KEY,
	"Incorrect command value");
_Static_assert(
	PTA_CYRES_GET_CERT_CHAIN == TA_CYRES_TEST_GET_CERT_CHAIN,
	"Incorrect command value");
_Static_assert(
	PTA_CYRES_GET_SEAL_KEY == TA_CYRES_TEST_GET_SEAL_KEY,
	"Incorrect command value");
#pragma GCC diagnostic pop
#pragma GCC diagnostic pop

struct sess_ctx {
	TEE_TASessionHandle cyres_pta_sess_handle;
};

/*
 * Called when the instance of the TA is created. This is the first call in
 * the TA.
 */
TEE_Result TA_CreateEntryPoint(void)
{
	return TEE_SUCCESS;
}

/*
 * Called when the instance of the TA is destroyed if the TA has not
 * crashed or panicked. This is the last call in the TA.
 */
void TA_DestroyEntryPoint(void)
{
}

/*
 * Called when a new session is opened to the TA. *sess_ctx can be updated
 * with a value to be able to identify this session in subsequent calls to the
 * TA.
 */
TEE_Result TA_OpenSessionEntryPoint(uint32_t param_types,
		TEE_Param  params[4], void **sess_ctx)
{
	TEE_Result res;
	const TEE_UUID cyres_pta_uuid = PTA_CYRES_UUID;
	struct sess_ctx *ctx = NULL;

	ctx = (struct sess_ctx *)TEE_Malloc(sizeof(struct sess_ctx), 0);
	if (!ctx)
		return TEE_ERROR_OUT_OF_MEMORY;

	res = TEE_OpenTASession(
			&cyres_pta_uuid,
			0,          // cancellationRequestTimeout
			param_types,
			params,
			&ctx->cyres_pta_sess_handle,
			NULL);     // returnOrigin

	if (res)
		goto end;

	*sess_ctx = ctx;

end:
	if (res && ctx)
		TEE_Free(ctx);

	return res;
}

/*
 * Called when a session is closed, sess_ctx hold the value that was
 * assigned by TA_OpenSessionEntryPoint().
 */
void TA_CloseSessionEntryPoint(void *sess_ctx)
{
	struct sess_ctx *ctx = (struct sess_ctx *)sess_ctx;
	TEE_CloseTASession(ctx->cyres_pta_sess_handle);
	TEE_Free(ctx);
}

/*
 * Called when a TA is invoked. sess_ctx hold that value that was
 * assigned by TA_OpenSessionEntryPoint(). The rest of the paramters
 * comes from normal world.
 */
TEE_Result TA_InvokeCommandEntryPoint(void *sess_ctx, uint32_t cmd_id,
		uint32_t param_types, TEE_Param params[TEE_NUM_PARAMS])
{
	struct sess_ctx *ctx = (struct sess_ctx *)sess_ctx;

	printf("Param types: 0x%x\n", param_types);

	if (params[0].memref.size == 0) {
		params[0].memref.size = 256;
		return TEE_ERROR_SHORT_BUFFER;
	}

	/* pass through to PTA_CYRES without modification */
	return TEE_InvokeTACommand(
			ctx->cyres_pta_sess_handle,
			0,          // cancellationRequestTimeout
			cmd_id,
			param_types,
			params,
			NULL);     // returnOrigin
}

