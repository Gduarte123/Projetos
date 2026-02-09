@echo off

echo.		
                                                                                                                    
:inicio

                                                           			        			           
ECHO #####################################################################
ECHO ##                                                                 ##
ECHO ##                   [ APLICACAO NO DOMINIO ]                      ##
ECHO ##                                                                 ##
ECHO #####################################################################
ECHO ## [ESCOLHA UMA OPCAO:]                                            ##
ECHO ##                                                                 ##
ECHO ## OPCAO(1): Alterar nome da maquina                               ##
ECHO ##                                                                 ##
ECHO ## OPCAO(2): Colocar maquina no dominio                            ##
ECHO ##                                                                 ##
ECHO ## OPCAO(3): Tirar maquina do dominio                              ##
ECHO ##                                                                 ##
ECHO ## OPCAO(4): Sair                                                  ##
ECHO #####################################################################


:: ######################################################################################

echo.
SET /p OPCAO=Digite a opcao desejada:

IF /i %OPCAO% EQU 1 (SET /P NOME_MAQUINA=Digite o novo nome para a maquina:) ELSE (GOTO OPCAO-2)
(WMIC COMPUTERSYSTEM WHERE NAME="%COMPUTERNAME%" CALL RENAME NAME="%NOME_MAQUINA%")

(TIMEOUT /T 01) 
(CLS)

ECHO    =====================================================================
ECHO                        [NOME ALTERADO COM SUCESSO]
ECHO    =====================================================================

(TIMEOUT /T 02)
(CLS)
(GOTO INICIO) 

:: ######################################################################################

:OPCAO-2

IF /i %OPCAO% EQU 2 (SET /P NOME_DOMINIO=Digite o nome do dominio:) ELSE (GOTO OPCAO-3)
echo.

IF /i %OPCAO% EQU 2 ECHO DESEJA ATIVAR A CONTA DE ADMINISTRADOR? & SET /P ESCOLHA= TECLE (S) PARA SIM OU (N) PARA NAO: 

IF /i %ESCOLHA% EQU S (NET USER ADMINISTRADOR /ACTIVE:YES) & 
(echo.) &
ECHO CONTA DE ADMINISTRADOR ATIVADA COM SUCESSO) & GOTO ALTERARDOMAIN

IF /i %ESCOLHA% EQU N GOTO ALTERARDOMAIN

:ALTERARDOMAIN

ECHO    =====================================================================
ECHO            [INSIRA AS CREDENCIAIS DO DOMINIO PARA PROSSEGUIR]
ECHO    =====================================================================

powershell -Command "Add-computer -DomainName %NOME_DOMINIO% -Restart"

:: ######################################################################################

:OPCAO-3

IF /i %opcao% EQU 3 (SET NOME_GRUPO=WORKGROUP) ELSE (GOTO OPCAO-4)

start /B /W wmic.exe /interactive:off ComputerSystem Where "Name='%computername%'" Call UnJoinDomainOrWorkgroup FUnjoinOptions=0
start /B /W wmic.exe /interactive:off ComputerSystem Where "Name='%computername%'" Call JoinDomainOrWorkgroup name="WORKGROUP" 

cls

ECHO    =====================================================================
ECHO                                [CONCLUIDO]
ECHO    =====================================================================
echo.   
ECHO    #############    #############   ####   #############    ######     
ECHO    #############    #############   ####       ####      #############
ECHO    ###              ####            ####       ####     ####       ####
ECHO    #############    #############   ####       ####    ####         ####
ECHO    ###              ####            ####       ####     ####       ####
ECHO    ###              #############   ####       ####      ############# 
ECHO    ###              #############   ####       ####         ######                                                           

TIMEOUT /T 03

ECHO DESEJA REINICIAR A MAQUINA AGORA?
echo.
SET /P ESCOLHA2= TECLE (S) PARA SIM OU (N) PARA NAO:

IF %ESCOLHA2% EQU N GOTO INICIO

IF %ESCOLHA2% EQU S ECHO REINICIANDO.............. & shutdown -r -t 1

:: ######################################################################################

:OPCAO-4

IF %opcao% EQU 4 (exit) ELSE (GOTO OPCAO-5)

:: ######################################################################################

:OPCAO-5

IF %OPCAO% NEQ 1 (
IF %OPCAO% NEQ 2 (
IF %OPCAO% NEQ 3 (
IF %OPCAO% NEQ 4 (
MSG * "DIGITE UMA OPCAO VALIDA!!
			)
		)
	)
)
PAUSE
cls 
goto inicio