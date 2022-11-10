############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("accountsettingsmodule")
#endregion

############################################################
#region modulesFromEnvironment
import { createClient } from "secret-manager-client"

import * as state from "./statemodule.js"
import * as utl from "./utilsmodule.js"
import *  as qrDisplay from "./qrdisplaymodule.js"
import *  as qrReader from "./qrreadermodule.js" 

############################################################
#strange... whynotwork?
idDisplay = document.getElementById("id-display")
idQrButton = document.getElementById("id-qr-button")
addKeyButton = document.getElementById("add-key-button")
deleteKeyButton = document.getElementById("delete-key-button")
importKeyInput = document.getElementById("import-key-input")
acceptKeyButton = document.getElementById("accept-key-button")
qrScanImport = document.getElementById("qr-scan-import")
floatingImport = document.getElementById("floating-import")
signatureImport = document.getElementById("signature-import")
copyExport = document.getElementById("copy-export")
qrExport = document.getElementById("qr-export")
floatingExport = document.getElementById("floating-export")
signatureExport = document.getElementById("signature-export")

#endregion

############################################################
idContent = null
currentClient = null

############################################################
export initialize = ->
    log "initialize"
    idContent = idDisplay.getElementsByClassName("display-frame-content")[0]

    idDisplay.addEventListener("click", idDisplayClicked)
    idQrButton.addEventListener("click", idQrButtonClicked)
    addKeyButton.addEventListener("click", addKeyButtonClicked)
    deleteKeyButton.addEventListener("click", deleteKeyButtonClicked)
    importKeyInput.addEventListener("change", importKeyInputChanged)
    acceptKeyButton.addEventListener("click", acceptKeyButtonClicked)
    qrScanImport.addEventListener("click", qrScanImportClicked)
    floatingImport.addEventListener("click", floatingImportClicked)
    signatureImport.addEventListener("click", signatureImportClicked)
    copyExport.addEventListener("click", copyExportClicked)
    qrExport.addEventListener("click", qrExportClicked)
    floatingExport.addEventListener("click", floatingExportClicked)
    signatureExport.addEventListener("click", signatureExportClicked)

    syncIdFromState()

    state.addOnChangeListener("publicKeyHex", syncIdFromState)
    state.addOnChangeListener("secretManagerURL", onServerURLChanged)

    await createCurrentClient()
    return

############################################################
#region internalFunctions
createCurrentClient = ->
    log "createCurrentClient"
    try
        secretKeyHex = utl.strip0x(state.load("secretKeyHex"))
        publicKeyHex = utl.strip0x(state.load("publicKeyHex"))
        serverURL = state.get("secretManagerURL")
        clientOptions = {secretKeyHex, publicKeyHex, serverURL}
        currentClient = await createClient(clientOptions)
    catch err then log err
    return

############################################################
onServerURLChanged = ->
    log "onServerURLChanged"
    serverURL = state.get("secretManagerURL")
    secretManagerClient.updateServerURL(serverURL)
    return

############################################################
syncIdFromState = ->
    log "syncIdFromState"
    idHex = state.load("publicKeyHex")
    log "idHex is "+idHex
    if utl.isValidKey(idHex)
        displayId(idHex)
        accountsettings.classList.remove("no-key")
    else
        displayId("") 
        accountsettings.classList.add("no-key")
    return

############################################################
displayId = (idHex) ->
    log "displayId"
    idContent.textContent = utl.add0x(idHex)
    return

############################################################
#region eventListeners
idDisplayClicked = ->
    log "idDisplayClicked"
    utl.copyToClipboard(idContent.textContent)
    return

idQrButtonClicked = ->
    log "idDisplayClicked"
    qrDisplay.displayCode(idContent.textContent)
    return

############################################################
addKeyButtonClicked = ->
    log "addKeyButtonClicked"
    try
        serverURL = state.load("secretManagerURL")
        currentClient = createClient({serverURL})
        await currentClient.keysReady
        log "publicKeyHex: #{currentClient.publicKeyHex}"
        log "secretKeyHex: #{currentClient.secretKeyHex}"
        
        state.save("secretKeyHex", currentClient.secretKeyHex)
        state.save("publicKeyHex", currentClient.publicKeyHex)
        state.save("accountId", currentClient.publicKeyHex)
    catch err
        log "Error when trying to create a new client on #{serverURL}\n#{err.message}"
    return

deleteKeyButtonClicked = ->
    log "deleteKeyButtonClicked"
    currentClient = null
    state.save("publicKeyHex", "")
    state.save("secretKeyHex", "")
    state.save("accountId", "")
    return

############################################################
importKeyInputChanged = ->
    log "importKeyInputChanged"
    validKey = utl.isValidKey(importKeyInput.value)
    log "input is valid key: "+validKey
    if validKey then accountsettings.classList.add("importing")
    else accountsettings.classList.remove("importing")
    return

acceptKeyButtonClicked = ->
    log "acceptKeyButtonClicked"
    key = utl.strip0x(importKeyInput.value)
    return unless utl.isValidKey(key)
    serverURL = state.load("secretManagerURL")
    currentClient = await createClient(key, null, serverURL)
    state.save("secretKeyHex", currentClient.secretKeyHex)
    state.save("publicKeyHex", currentClient.publicKeyHex)
    state.save("accountId", currentClient.publicKeyHex)
    importKeyInput.value = ""
    importKeyInputChanged()
    return

############################################################
qrScanImportClicked = ->
    log "qrScanImportClicked"
    try
        key = await qrReader.read()
        importKeyInput.value = key
        importKeyInputChanged()
    catch err then log err
    return

floatingImportClicked = ->
    log "floatingImportClicked"
    ##TODO implement
    return

signatureImportClicked = ->
    log "signatureImportClicked"
    ##TODO implement
    return

############################################################
copyExportClicked = ->
    log "copyExportClicked"
    key = state.get("secretKeyHex")
    utl.copyToClipboard(key)
    return

qrExportClicked = ->
    log "qrExportClicked"
    key = state.get("secretKeyHex")
    qrDisplay.displayCode(key)
    return

floatingExportClicked = ->
    log "floatingExportClicked"
    return

signatureExportClicked = ->
    log "signatureExportClicked"
    return

#endregion

#endregion

############################################################
export getClient = -> currentClient

#92e102b2b2ef0d5b498fae3d7a9bbc94fc6ddc9544159b3803a6f4d239d76d62