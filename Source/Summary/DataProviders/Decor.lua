local DECOR_TABLE_LAYOUT = {
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerParameters = { "name" },
    headerText = AUCTIONATOR_L_NAME,
    cellTemplate = "AuctionatorItemKeyCellTemplate",
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_QUANTITY,
    headerParameters = { "quantity" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "quantity" },
    width = 70
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_UNIT_PRICE,
    headerParameters = { "price" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "price" },
    width = 150,
  },
}

CollectionatorSummaryDecorDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function CollectionatorSummaryDecorDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)

  Auctionator.EventBus:Register(self, {
    Collectionator.Events.SummaryDecorLoadStart,
    Collectionator.Events.SummaryDecorLoadEnd,
    Collectionator.Events.DecorPurchased,
  })
  Auctionator.EventBus:RegisterSource(self, "CollectionatorSummaryDecorDataProvider")

  self.dirty = false
  self.decor = {}
end

function CollectionatorSummaryDecorDataProviderMixin:OnShow()
  self.focussedLink = nil
  Auctionator.EventBus:Register(self, {
    Collectionator.Events.SummaryFocusItem,
  })

  if self.dirty then
    self:Refresh()
  end
end

function CollectionatorSummaryDecorDataProviderMixin:ReceiveEvent(eventName, eventData, eventData2)
  if eventName == Collectionator.Events.SummaryDecorLoadStart then
    self:Reset()
    self.onSearchStarted()
    self:GetParent().NoFullScanText:Hide()
    self:GetParent().ShowingXResultsText:Hide()
  elseif eventName == Collectionator.Events.SummaryDecorLoadEnd then
    self.decor = eventData
    self.fullScan = eventData2

    self.dirty = true
    if self:IsVisible() then
      self:Refresh()
    end
  elseif eventName == Collectionator.Events.DecorPurchased then
    self.dirty = true
    if self:IsVisible() and not self:GetParent().IncludeCollected:GetChecked() then
      self:Refresh()
    end
  elseif eventName == Collectionator.Events.SummaryFocusItem then
    self.focussedItem = eventData
    self.dirty = true
    self:Refresh()
  end
end

local COMPARATORS = {
  price = Auctionator.Utilities.NumberComparator,
  name = Auctionator.Utilities.StringComparator,
  quantity = Auctionator.Utilities.NumberComparator,
}

function CollectionatorSummaryDecorDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self.onUpdate(self.results)
end

local function IsDecorCollected(itemID)
  if not C_HousingCatalog then
    return false
  end
  local catalogInfo = C_HousingCatalog.GetCatalogEntryInfoByItem(itemID, true)
  if not catalogInfo or not catalogInfo.entryID then
    return false
  end
  local entrySubtype = catalogInfo.entryID.entrySubtype
  return entrySubtype == 2 or entrySubtype == 3
end

function CollectionatorSummaryDecorDataProviderMixin:Refresh()
  if self.dirty then
    self.onPreserveScroll()
  else
    self.onResetScroll()
  end

  self.dirty = false
  self:Reset()

  self.onSearchStarted()

  local filtered = Collectionator.Utilities.SummaryExtractWantedItems(Collectionator.Utilities.SummaryGroupedByID(self.decor, self.fullScan), self.fullScan)
  local results = {}

  -- Filter decor
  for _, decorInfo in ipairs(filtered) do
    local info = self.fullScan[decorInfo.index]

    local check = true

    if not self:GetParent().IncludeCollected:GetChecked() then
      check = check and not IsDecorCollected(decorInfo.id)
      if Collectionator.State.Purchases and Collectionator.State.Purchases.Decor then
        check = check and not Collectionator.State.Purchases.Decor[decorInfo.id]
      end
    end

    local searchString = self:GetParent().TextFilter:GetText()
    if decorInfo.itemKeyInfo and decorInfo.itemKeyInfo.itemName then
      check = check and string.find(string.lower(decorInfo.itemKeyInfo.itemName), string.lower(searchString), 1, true)
    end

    if check and decorInfo.itemKeyInfo then
      table.insert(results, {
        index = decorInfo.index,
        itemName = Collectionator.Utilities.SummaryColorName(decorInfo.itemKeyInfo),
        name = decorInfo.itemKeyInfo.itemName,
        quantity = decorInfo.quantity,
        price = info.minPrice,
        itemLink = decorInfo.itemLink, -- Used for tooltips
        itemKey = info.itemKey,
        itemKeyInfo = decorInfo.itemKeyInfo,
        iconTexture = decorInfo.itemKeyInfo.iconFileID,
        selected = Auctionator.Utilities.ItemKeyString(info.itemKey) == self.focussedItem,
      })
    end
  end

  self:GetParent().ShowingXResultsText:SetText(COLLECTIONATOR_L_SHOWING_X_RESULTS:format(#results))
  self:GetParent().ShowingXResultsText:Show()

  Collectionator.Utilities.SortByPrice(results, self.fullScan)
  self:AppendEntries(results, true)
  if self:IsVisible() then
    Auctionator.EventBus:Fire(self, Collectionator.Events.SummaryDisplayedResultsUpdated, results)
  end
end

function CollectionatorSummaryDecorDataProviderMixin:UniqueKey(entry)
  return tostring(entry.index)
end

function CollectionatorSummaryDecorDataProviderMixin:GetTableLayout()
  return DECOR_TABLE_LAYOUT
end

Auctionator.Config.Create("COLLECTIONATOR_COLUMNS_DECOR", "collectionator_columns_decor", {})

function CollectionatorSummaryDecorDataProviderMixin:GetColumnHideStates()
  return Auctionator.Config.Get(Auctionator.Config.Options.COLLECTIONATOR_COLUMNS_DECOR)
end


function CollectionatorSummaryDecorDataProviderMixin:GetRowTemplate()
  return "CollectionatorSummaryToyMountRowTemplate"
end
