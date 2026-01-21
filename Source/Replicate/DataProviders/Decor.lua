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

CollectionatorReplicateDecorDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function CollectionatorReplicateDecorDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)

  Auctionator.EventBus:Register(self, {
    Collectionator.Events.DecorLoadStart,
    Collectionator.Events.DecorLoadEnd,
    Collectionator.Events.DecorPurchased,
  })
  Auctionator.EventBus:RegisterSource(self, "CollectionatorReplicateDecorDataProvider")

  self.dirty = false
  self.decor = {}
end

function CollectionatorReplicateDecorDataProviderMixin:OnShow()
  self.focussedLink = nil
  Auctionator.EventBus:Register(self, {
    Collectionator.Events.ReplicateFocusLink,
  })

  if self.dirty then
    self:Refresh()
  end
end

function CollectionatorReplicateDecorDataProviderMixin:ReceiveEvent(eventName, eventData, eventData2)
  if eventName == Collectionator.Events.DecorLoadStart then
    self:Reset()
    self.onSearchStarted()
    self:GetParent().NoFullScanText:Hide()
    self:GetParent().ShowingXResultsText:Hide()
  elseif eventName == Collectionator.Events.DecorLoadEnd then
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
  elseif eventName == Collectionator.Events.ReplicateFocusLink then
    self.focussedLink = eventData
    self.dirty = true
    self:Refresh()
  end
end

local COMPARATORS = {
  price = Auctionator.Utilities.NumberComparator,
  name = Auctionator.Utilities.StringComparator,
  quantity = Auctionator.Utilities.NumberComparator,
}

function CollectionatorReplicateDecorDataProviderMixin:Sort(fieldName, sortDirection)
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

function CollectionatorReplicateDecorDataProviderMixin:Refresh()
  if self.dirty then
    self.onPreserveScroll()
  else
    self.onResetScroll()
  end

  self.dirty = false
  self:Reset()

  self.onSearchStarted()

  local filtered = Collectionator.Utilities.ReplicateExtractWantedItems(Collectionator.Utilities.ReplicateGroupedByID(self.decor, self.fullScan), self.fullScan)
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
    check = check and string.find(string.lower(info.replicateInfo[1]), string.lower(searchString), 1, true)

    if check then
      table.insert(results, {
        index = decorInfo.index,
        itemName = Collectionator.Utilities.ColorName(info.itemLink, info.replicateInfo[1]),
        name = info.replicateInfo[1],
        quantity = decorInfo.quantity,
        price = Collectionator.Utilities.GetPrice(info.replicateInfo),
        itemLink = info.itemLink, -- Used for tooltips
        iconTexture = info.replicateInfo[2],
        selected = info.itemLink == self.focussedLink,
      })
    end
  end

  self:GetParent().ShowingXResultsText:SetText(COLLECTIONATOR_L_SHOWING_X_RESULTS:format(#results))
  self:GetParent().ShowingXResultsText:Show()

  Collectionator.Utilities.SortByPrice(results, self.fullScan)
  self:AppendEntries(results, true)
  if self:IsVisible() then
    Auctionator.EventBus:Fire(self, Collectionator.Events.ReplicateDisplayedResultsUpdated, results)
  end
end

function CollectionatorReplicateDecorDataProviderMixin:UniqueKey(entry)
  return tostring(entry.index)
end

function CollectionatorReplicateDecorDataProviderMixin:GetTableLayout()
  return DECOR_TABLE_LAYOUT
end

Auctionator.Config.Create("COLLECTIONATOR_COLUMNS_DECOR", "collectionator_columns_decor", {})

function CollectionatorReplicateDecorDataProviderMixin:GetColumnHideStates()
  return Auctionator.Config.Get(Auctionator.Config.Options.COLLECTIONATOR_COLUMNS_DECOR)
end


function CollectionatorReplicateDecorDataProviderMixin:GetRowTemplate()
  return "CollectionatorReplicateToyMountRowTemplate"
end
