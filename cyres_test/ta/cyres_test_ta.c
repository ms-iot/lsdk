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
	PTA_CYRES_GET_PRIVATE_KEY_SIZE == TA_CYRES_TEST_GET_PRIVATE_KEY_SIZE,
	"Incorrect command value");
_Static_assert(
	PTA_CYRES_GET_PRIVATE_KEY == TA_CYRES_TEST_GET_PRIVATE_KEY,
	"Incorrect command value");
_Static_assert(
	PTA_CYRES_GET_PUBLIC_KEY_SIZE == TA_CYRES_TEST_GET_PUBLIC_KEY_SIZE,
	"Incorrect command value");
_Static_assert(
	PTA_CYRES_GET_PUBLIC_KEY == TA_CYRES_TEST_GET_PUBLIC_KEY,
	"Incorrect command value");
_Static_assert(
	PTA_CYRES_GET_CERT_CHAIN_SIZE == TA_CYRES_TEST_GET_CERT_CHAIN_SIZE,
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

static void cleanup_temp_buffers(uint32_t param_types,
		TEE_Param params[TEE_NUM_PARAMS], int index)
{
	int i;
	for (i = 0; i < index; i++) {
		switch (TEE_PARAM_TYPE_GET(param_types, i)) {
		case TEE_PARAM_TYPE_MEMREF_OUTPUT:
			TEE_Free(params[i].memref.buffer);
			params[i].memref.buffer = NULL;
			break;
		default:
			break;
		}
	}
}

/*
 * Called when a TA is invoked. sess_ctx hold that value that was
 * assigned by TA_OpenSessionEntryPoint(). The rest of the paramters
 * comes from normal world.
 */
TEE_Result TA_InvokeCommandEntryPoint(void *sess_ctx, uint32_t cmd_id,
		uint32_t param_types, TEE_Param params[TEE_NUM_PARAMS])
{
	TEE_Result res;
	int i;
	struct sess_ctx *ctx = (struct sess_ctx *)sess_ctx;
	TEE_Param pta_params[TEE_NUM_PARAMS];

	memcpy(pta_params, params, sizeof(pta_params));

	/*
	 * Output buffers need to be proxied. Other buffer types may
	 * also need to be proxied, but output is the only type currently
	 * tested.
	 */
	for (i = 0; i < TEE_NUM_PARAMS; i++) {
		switch (TEE_PARAM_TYPE_GET(param_types, i)) {
		case TEE_PARAM_TYPE_MEMREF_OUTPUT:
			pta_params[i].memref.buffer = TEE_Malloc(
				pta_params[i].memref.size, 0);

			if (!pta_params[i].memref.buffer) {
				EMSG("Failed to allocate proxy buffer for "
				     "param %d, size %d",
				     i, pta_params[i].memref.size);

				cleanup_temp_buffers(
					param_types, pta_params, i);

				return TEE_ERROR_OUT_OF_MEMORY;
			}
			break;
		default:
			break;
		}
	}

	/* pass through to PTA_CYRES without modification */
	res = TEE_InvokeTACommand(
			ctx->cyres_pta_sess_handle,
			0,          // cancellationRequestTimeout
			cmd_id,
			param_types,
			pta_params,
			NULL);     // returnOrigin

	/* copy output buffers back to user */
	for (i = 0; i < TEE_NUM_PARAMS; i++) {
		switch (TEE_PARAM_TYPE_GET(param_types, i)) {
		case TEE_PARAM_TYPE_MEMREF_OUTPUT:
			memcpy(params[i].memref.buffer,
			       pta_params[i].memref.buffer,
			       params[i].memref.size);

			TEE_Free(pta_params[i].memref.buffer);
			pta_params[i].memref.buffer = params[i].memref.buffer;
		default:
			break;
		}
	}

	/* ensure that any value types get returned to user */
	memcpy(params, pta_params, sizeof(pta_params));

	return res;
}

