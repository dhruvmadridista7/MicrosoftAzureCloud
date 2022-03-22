@Echo Off
:GetInput
Set "AgentDir="
Set /P "AgentDir=Please provide the location where you downloaded the mma agent .exe file:" /c
CD /D "%AgentDir%"
MMASetup-AMD64.exe /c 
setup.exe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID="af370230-22db-425e-915f-78bdb1ddf80c" OPINSIGHTS_WORKSPACE_KEY="gHIicN1jxmGcyXeQJCw/wE64cuLb0VukNPGf6d88h4at+kX7uwFcQ7r7EchyMH+7MoGlmEt2uhBDRQaleZrngg==" AcceptEndUserLicenseAgreement=1
@echo off
echo msgbox "Installation complete!" > "%temp%\popup.vbs"
wscript.exe "%temp%\popup.vbs"