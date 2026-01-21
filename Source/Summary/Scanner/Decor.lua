CollectionatorSummaryDecorScannerFrameMixin = CreateFromMixins(CollectionatorSummaryScannerFrameMixin)

function CollectionatorSummaryDecorScannerFrameMixin:OnLoad()
  CollectionatorSummaryScannerFrameMixin.OnLoad(self)

  self.SCAN_START_EVENT = Collectionator.Events.SummaryDecorLoadStart
  self.SCAN_END_EVENT = Collectionator.Events.SummaryDecorLoadEnd
  self.SCAN_STEP =  Collectionator.Constants.SummaryScanDecorStepSize
end

function CollectionatorSummaryDecorScannerFrameMixin:GetSourceName()
  return "CollectionatorSummaryDecorScannerFrameMixin"
end

function CollectionatorSummaryDecorScannerFrameMixin:GetItem(index, itemKeyInfo, scanInfo)
  local itemID = scanInfo.itemKey.itemID
  
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
