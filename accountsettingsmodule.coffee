accountsettingsmodule = {name: "accountsettingsmodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["accountsettingsmodule"]?  then console.log "[accountsettingsmodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
#region modulesFromEnvironment
secretManagerClientFactory = require("secret-manager-client")

############################################################
utl = null 
state = null
qrDisplay = null
qrReader = null 

#endregion

############################################################
idContent = null
currentClient = null

############################################################
accountsettingsmodule.initialize = ->
    log "accountsettingsmodule.initialize"
    utl = allModules.utilmodule
    state = allModules.statemodule
    qrDisplay = allModules.qrdisplaymodule
    qrReader = allModules.qrreadermodule

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
        key = utl.strip0x(state.load("secretKeyHex"))
        id = utl.strip0x(state.load("publicKeyHex"))
        serverURL = state.get("secretManagerURL")
        if utl.isValidKey(key) and utl.isValidKey(id) then currentClient = await secretManagerClientFactory.createClient(key, id, serverURL)
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
        currentClient = await secretManagerClientFactory.createClient(null, null, serverURL)
        state.save("secretKeyHex", currentClient.secretKeyHex)
        state.save("publicKeyHex", currentClient.publicKeyHex)
        state.save("accountId", currentClient.publicKeyHex)
    catch err
        log err
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
    currentClient = await secretManagerClientFactory.createClient(key, null, serverURL)
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
#region exposedFunctions
accountsettingsmodule.getClient = -> currentClient

#endregion

module.exports = accountsettingsmodule

#92e102b2b2ef0d5b498fae3d7a9bbc94fc6ddc9544159b3803a6f4d239d76d62