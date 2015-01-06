@REM cria seu proprio config.bat setando o valor de INSTALATION_DIR
@REM ex: set INSTALATION_DIR=C:\Program Files (x86)\IAR Systems\Embedded Workbench 6.5
@REM
@SET INSTALATION_DIR=
CALL config.bat

@del *.LOG

@REM checa se a pasta está corente com o repositorio
perl ChecaPastaSVN.pl
@if errorlevel 1 (
@	echo ERRO: Geracao cancelado por causa de erro no repositorio
@	exit /b )

@REM --------------------------------------------------------------------------------------------------------------------
@REM                                           COMPILAÇÂO RELEASE
@REM --------------------------------------------------------------------------------------------------------------------

@time /t > 3100_BTH_GPRS_BUILD.LOG
@date /t >> 3100_BTH_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3100.ewp     -build Release_BTH_GPRS  -log all >> 3100_BTH_GPRS_BUILD.LOG

@time /t > 3100_WLAN_GPRS_BUILD.LOG
@date /t >> 3100_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3100.ewp     -build Release_WLAN_GPRS -log all >> 3100_WLAN_GPRS_BUILD.LOG

@time /t > 3200_BTH_GPRS_BUILD.LOG
@date /t >> 3200_BTH_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200.ewp     -build Release_BTH_GPRS  -log all >> 3200_BTH_GPRS_BUILD.LOG

@time /t > 3200_WLAN_GPRS_BUILD.LOG
@date /t >> 3200_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200.ewp     -build Release_WLAN_GPRS -log all >> 3200_WLAN_GPRS_BUILD.LOG

@time /t > 3200PLM_WLAN_GPRS_BUILD.LOG
@date /t >> 3200PLM_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_plm.ewp -build Release_WLAN_GPRS -log all >> 3200PLM_WLAN_GPRS_BUILD.LOG

@REM @time /t > 3200ETD_BTH_GPRS_BUILD.LOG
@REM @date /t >> 3200ETD_BTH_GPRS_BUILD.LOG
@REM "%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_etd.ewp -build Release_BTH_GPRS -log all >> 3200ETD_BTH_GPRS_BUILD.LOG

@time /t > 3200ETD_WLAN_GPRS_BUILD.LOG
@date /t >> 3200ETD_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_etd.ewp -build Release_WLAN_GPRS -log all >> 3200ETD_WLAN_GPRS_BUILD.LOG

@REM Cria os arquivos de projeto para os projetos para debug e simulação:
perl EditaArqEWP.pl

@REM --------------------------------------------------------------------------------------------------------------------
@REM                                           COMPILAÇÂO DEBUG_GPS
@REM --------------------------------------------------------------------------------------------------------------------
@REM Compila os projetos para debugar o GPS
@REM 3100
@time /t > 3100_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
@date /t >> 3100_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3100_DEBUG_GPS.ewp -build Release_WLAN_GPRS -log all >> 3100_DEBUG_GPS_WLAN_GPRS_BUILD.LOG

@REM Bluetooth
@time /t > 3100_DEBUG_GPS_BTH_GPRS_BUILD.LOG
@date /t >> 3100_DEBUG_GPS_BTH_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3100_DEBUG_GPS.ewp -build Release_BTH_GPRS -log all >> 3100_DEBUG_GPS_BTH_GPRS_BUILD.LOG

@REM 3200
@time /t > 3200_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
@date /t >> 3200_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_DEBUG_GPS.ewp -build Release_WLAN_GPRS -log all >> 3200_DEBUG_GPS_WLAN_GPRS_BUILD.LOG

@REM Bluetooth
@time /t > 3200_DEBUG_GPS_BTH_GPRS_BUILD.LOG
@date /t >> 3200_DEBUG_GPS_BTH_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_DEBUG_GPS.ewp -build Release_BTH_GPRS -log all >> 3200_DEBUG_GPS_BTH_GPRS_BUILD.LOG

@REM PLM
@time /t > 3200PLM_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
@date /t >> 3200PLM_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_plm_DEBUG_GPS.ewp -build Release_WLAN_GPRS -log all >> 3200PLM_DEBUG_GPS_WLAN_GPRS_BUILD.LOG

@REM ETD
@time /t > 3200ETD_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
@date /t >> 3200ETD_DEBUG_GPS_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_etd_DEBUG_GPS.ewp -build Release_WLAN_GPRS -log all >> 3200ETD_DEBUG_GPS_WLAN_GPRS_BUILD.LOG

@REM --------------------------------------------------------------------------------------------------------------------
@REM                                           COMPILAÇÂO TESTE_CEC
@REM --------------------------------------------------------------------------------------------------------------------
@REM Compila os projetos para simular o CEC - WIFI e Bluetooth
@REM 3100
@REM WiFi
@time /t > 3100_TESTE_CEC_WLAN_GPRS_BUILD.LOG
@date /t >> 3100_TESTE_CEC_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3100_TESTE_CEC.ewp -build Release_WLAN_GPRS -log all >> 3100_TESTE_CEC_WLAN_GPRS_BUILD.LOG

@REM Bluetooth
@time /t > 3100_TESTE_CEC_BTH_GPRS_BUILD.LOG
@date /t >> 3100_TESTE_CEC_BTH_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3100_TESTE_CEC.ewp -build Release_BTH_GPRS -log all >> 3100_TESTE_CEC_BTH_GPRS_BUILD.LOG

@REM 3200
@REM WiFi
@time /t > 3200_TESTE_CEC_WLAN_GPRS_BUILD.LOG
@date /t >> 3200_TESTE_CEC_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_TESTE_CEC.ewp -build Release_WLAN_GPRS -log all >> 3200_TESTE_CEC_WLAN_GPRS_BUILD.LOG

@REM Bluetooth
@time /t > 3200_TESTE_CEC_BTH_GPRS_BUILD.LOG
@date /t >> 3200_TESTE_CEC_BTH_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_TESTE_CEC.ewp -build Release_BTH_GPRS -log all >> 3200_TESTE_CEC_BTH_GPRS_BUILD.LOG

@REM PLM - WiFi
@time /t > 3200PLM_TESTE_CEC_WLAN_GPRS_BUILD.LOG
@date /t >> 3200PLM_TESTE_CEC_WLAN_GPRS_BUILD.LOG
"%INSTALATION_DIR%\common\bin\IarBuild.exe" cpu3200_plm_TESTE_CEC.ewp -build Release_WLAN_GPRS -log all >> 3200PLM_TESTE_CEC_WLAN_GPRS_BUILD.LOG

@REM ETD - ETD Não existe opção de compilação para teste do CEC - utiliza DEBUG_GPS para definir a posição

@REM Os firmwares agora deveriam está compilados sem erros
@REM Chama perl script para verificar e exportar para a pasta correto.

perl ExportaHexa.pl

