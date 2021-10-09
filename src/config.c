/*************************************************************************************/
/* Automatically-generated file. Do not edit! */
/*************************************************************************************/
#include "tuya_zigbee_sdk.h"
#include "config.h"


char *g_firmware_name = FIRMWARE_NAME;
uint8_t g_firmware_ver = FIRMWARE_VER;

void firmware_config(void)
{

///@name Zigbee basic information configuration
/**
 * @note Register tuya-related information to the SDK, the SDK will be automatically called, you do not need to use
 * @param[in] {model_id} modle id attribute of basic cluster
 * @param[in] {pid_prefix} manufacture name attribute(0-8bytes) of basic cluster
 * @param[in] {pid} manufacture name attribute(9-16bytes) of basic cluster
 * @return none
 */
    dev_register_base_info("RONAN_ID", "RONAN_SA", "RONAN_FIRMWARE");
}
