CollectionatorReplicateDecorScannerFrameMixin = CreateFromMixins(CollectionatorReplicateScannerFrameMixin)

function CollectionatorReplicateDecorScannerFrameMixin:OnLoad()
  CollectionatorReplicateScannerFrameMixin.OnLoad(self)

  self.SCAN_START_EVENT = Collectionator.Events.DecorLoadStart
  self.SCAN_END_EVENT = Collectionator.Events.DecorLoadEnd
  self.SCAN_STEP =  Collectionator.Constants.DECOR_SCAN_STEP_SIZE
end

function CollectionatorReplicateDecorScannerFrameMixin:GetSourceName()
  return "CollectionatorReplicateDecorScannerFrameMixin"
end

function CollectionatorReplicateDecorScannerFrameMixin:GetItem(index, link, scanInfo)
  local itemID = scanInfo.replicateInfo[17]
  
  if not C_HousingCatalog then
    return
  end
  
  local catalogInfo = C_HousingCatalog.GetCatalogEntryInfoByItem(itemID, false)
  if not catalogInfo then
    return
  end

  return {
    index = index,
    id = itemID,
  }
end
