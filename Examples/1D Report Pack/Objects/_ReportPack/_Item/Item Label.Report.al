report 81273 "MOB1D Item Label"
{
    Caption = 'Mobile WMS - Item Label (1D)';
    /* #if BC20+ */
    AdditionalSearchTerms = 'Mobile WMS Item Label Tasklet Print Barcode', Locked = true;
    DefaultRenderingLayout = "Item Label 3x2"; // Multiple Layout defined below in the "Rendering" section
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    WordMergeDataItem = CopyLoop;

    dataset
    {
        dataitem(CopyLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem(Item; Item)
            {
                DataItemTableView = sorting("No.");
                RequestFilterFields = "No.";
                RequestFilterHeading = 'Items';

                column(No_; "No.")
                {
                }
                column(Description; Description)
                {
                }
                // Column that stores the barcode encoded string
                column(Barcode; EncodedBarcodeText)
                {
                }
                column(BarcodeAsTxt; BarcodeTxt)
                {
                }
                column(ItemVariantCode; ItemVariantCodeReq)
                {
                }
                column(Quantity; QuantityTxt)
                {
                }
                column(UoM; UoMReq)
                {
                }
                column(LotNo; LotNoReq)
                {
                }
                column(SerialNo; SerialNoReq)
                {
                }
                column(ExpirationDate; ExpirationDateTxt)
                {
                }
                column(PackageNo; PackageNoReq)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    // Add values to the AI dictionary. 
                    // Report extensions may add values to the AiDictionary in the OnBeforeAfterGetRecord trigger - these values are not overwritten
                    AddValuesToAiDictionary();

                    // Encode dictionary as 1D GS1 Code128
                    EncodedBarcodeText := Mob1DInternalMobFunctions.GetEncodedBarcodeText("Barcode Font Provider"::IDAutomation1D, "Barcode Symbology"::Code128, InternalAiDictionary);

                    // Required to have dictionary available in the OnAfterAfterGetRecord
                    AiDictionary := InternalAiDictionary;

                    // Prepare for loop
                    Clear(InternalAiDictionary);

                    // Misc. formatting 
                    // Format Date shown on report, it will be formatted according to regional setting
                    ExpirationDateTxt := MobWmsToolbox.Date2TextAsDisplayFormat(ExpirationDateReq);

                    // Format Quantity shown on report, it will be formatted according to regional setting
                    QuantityTxt := MobWmsToolbox.Decimal2TextAsDisplayFormat(QuantityReq);

                    // Get Item [Variant] Description
                    Description := MobWmsToolbox.GetItemDescription(Item."No.", ItemVariantCodeReq);
                end;
            }

            trigger OnPreDataItem()
            begin
                NoOfLoops := Abs(NoOfCopiesReq) + 1;
                CopyLoop.SetRange(Number, 1, NoOfLoops);
            end;
        }

    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(NoOfCopies; NoOfCopiesReq)
                    {
                        ApplicationArea = All;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                }
                group(OptionalValues)
                {
                    Caption = 'Optional Values';
                    field(ItemVariantCode; ItemVariantCodeReq)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Variant Code';
                        ToolTip = 'Specifies the Item Variant Code';
                    }
                    field(Quantity; QuantityReq)
                    {
                        ApplicationArea = All;
                        Caption = 'Quantity';
                        ToolTip = 'The number of units, each label represents';
                        DecimalPlaces = 0 : 2;
                        BlankZero = true;
                    }
                    field(UoM; UoMReq)
                    {
                        ApplicationArea = All;
                        Caption = 'Unit of Measure';
                        ToolTip = 'Specifies the Unit of Measure';
                    }
                    field(LotNo; LotNoReq)
                    {
                        ApplicationArea = All;
                        Caption = 'Lot No.';
                        ToolTip = 'Specifies the Lot No.';
                    }
                    field(ExpirationDate; ExpirationDateReq)
                    {
                        ApplicationArea = All;
                        Caption = 'Expiration Date';
                        ToolTip = 'Specifies the Expiration Date';
                    }
                    field(SerialNo; SerialNoReq)
                    {
                        ApplicationArea = All;
                        Caption = 'Serial No.';
                        ToolTip = 'Specifies the Serial No.';
                    }
                    field(PackageNo; PackageNoReq)
                    {
                        ApplicationArea = All;
                        Caption = 'Package No.';
                        ToolTip = 'Specifies the Package No.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout("Item Label 2x1")
        {
            Type = RDLC;
            Caption = 'Item Label 2x1';
            Summary = 'Mobile WMS - Item Label 2x1 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 2x1.rdl';
        }
        layout("Item Label 3x2")
        {
            Type = RDLC;
            Caption = 'Item Label 3x2';
            Summary = 'Mobile WMS - Item Label 3x2 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 3x2.rdl';
        }
        layout("Item Label 4x1")
        {
            Type = RDLC;
            Caption = 'Item Label 4x1';
            Summary = 'Mobile WMS - Item Label 4x1 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 4x1.rdl';
        }
        layout("Item Label 4x2")
        {
            Type = RDLC;
            Caption = 'Item Label 4x2';
            Summary = 'Mobile WMS - Item Label 4x2 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 4x2.rdl';
        }
        layout("Item Label 4x3")
        {
            Type = RDLC;
            Caption = 'Item Label 4x3';
            Summary = 'Mobile WMS - Item Label 4x3 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 4x3.rdl';
        }
        layout("Item Label 4x6")
        {
            Type = RDLC;
            Caption = 'Item Label 4x6';
            Summary = 'Mobile WMS - Item Label 4x6 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 4x6.rdl';
        }
        layout("Item Label 8x11")
        {
            Type = RDLC;
            Caption = 'Item Label 8x11';
            Summary = 'Mobile WMS - Item Label 8x11 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 8x11.rdl';
        }
        layout("Item Label 4x6 (Word)")
        {
            Type = Word;
            Caption = 'Item Label 4x6 (Word)';
            Summary = 'Mobile WMS - Item Label 4x6 with encoded GS1 Code128';
            LayoutFile = './Objects/_ReportPack/_Item/MOB Item Label 4x6.docx';
        }
    }

    labels
    {
        No_Caption = 'No.';
        Description_Caption = 'Description';
        ItemVariant_Caption = 'Variant Code';
        Quantity_Caption = 'Quantity';
        LotNo_Caption = 'Lot No.';
        SerialNo_Caption = 'Serial No.';
        ExpirationDate_Caption = 'Expiration Date';
        PackageNo_Caption = 'Package No.';
    }

    /// <summary>
    /// Apply the values in sequence to encode as Ai´s acording to the GS1 standard
    /// </summary>
    local procedure AddValuesToAiDictionary()
    var
        ItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        ReferenceNo: Text;
        Ai310n: Text[1];
        Ai310Qty: Text;
        AiKey: Text;
        AiValue: Text;
    begin
        // Quantity encoded using 310n when decimal are used, else 37
        if QuantityReq <> 0 then
            if Mob1DInternalMobFunctions.QuantityTransformedToAI310n(QuantityReq, Ai310n, Ai310Qty) then
                Add_AiAndValueIfKeyNotExists('310' + Ai310n, Ai310Qty)
            else
                Add_AiAndValueIfKeyNotExists('37', Format(QuantityReq, 0, 9)); // Ensure no thousand separator are added, as it could be scanned as a decimal separator by the mobile app

        // Lot No. encoded using Ai 10
        Add_AiAndValueIfKeyNotExists('10', LotNoReq);

        // Exp. Date encoded using Ai 17
        if ExpirationDateReq <> 0D then
            Add_AiAndValueIfKeyNotExists('17', MobTypeHelper.FormatDateAsYYMMDD(ExpirationDateReq));

        // Serial No. encoded using Ai 21
        Add_AiAndValueIfKeyNotExists('21', SerialNoReq);

        // Package No. encoded using Ai 92
        Add_AiAndValueIfKeyNotExists('92', PackageNoReq);

        // Item Reference encoded using Ai 91
        ReferenceNo := ItemReferenceMgt.GetFirstReferenceNo(Item."No.", ItemVariantCodeReq, UoMReq);
        if ReferenceNo = '' then
            if (ItemVariantCodeReq = '') and (UoMReq in ['', Item."Base Unit of Measure"]) then
                ReferenceNo := Item."No."
            else
                Error(NoValidReferenceErr, Item."No.");

        Add_AiAndValueIfKeyNotExists('91', ReferenceNo);

        // Remove empty AIs to avoid encoding them (Can be added by a Report Extension to prevent them from being added here)
        foreach AiKey in InternalAiDictionary.Keys() do begin
            InternalAiDictionary.Get(AiKey, AiValue);
            if AiValue = '' then
                InternalAiDictionary.Remove(AiKey);
        end;
    end;

    /// <summary>
    /// Adds a Application Identifier (AI) and its value to the AiDictionary.
    /// AI added in the OnBeforeAfterGetRecord will not be overwritten by Mobile WMS.
    /// If the AI is already present or marked to be excluded, the insertion will fail.
    /// </summary>
    procedure Add_CustomAiAndValue(_GS1AI: Text; _InputValue: Text)
    begin
        if _GS1AI <> '' then
            InternalAiDictionary.Add(_GS1AI, _InputValue);
    end;

    /// <summary>
    /// Prevents an AI to be added to the AiDictionary by Mobile WMS.
    /// This enables customizations to omit an AI to be part of the encoded GS1 barcode.
    /// </summary>
    procedure Exclude_Ai(_GS1AI: Text)
    begin
        InternalAiDictionary.Set(_GS1AI, ''); // Blank values will be removed before the barcode is encoded
    end;

    local procedure Add_AiAndValueIfKeyNotExists(_GS1AI: Text; _InputValue: Text)
    begin
        if (_GS1AI = '') or (_InputValue = '') then
            exit;

        if not InternalAiDictionary.ContainsKey(_GS1AI) then
            InternalAiDictionary.Add(_GS1AI, _InputValue);
    end;

    /// <summary>
    /// Sets the Item Variant Code on the request page
    /// </summary>
    procedure Set_VariantCode(_VariantCode: Code[10])
    begin
        ItemVariantCodeReq := _VariantCode;
    end;
    /// <summary>
    /// Sets the Quantity on the request page
    /// </summary>
    procedure Set_Quantity(_Quantity: Decimal)
    begin
        QuantityReq := _Quantity;
    end;
    /// <summary>
    /// Sets the Unit of Measure on the request page
    /// </summary>
    procedure Set_UoM(_UoM: Code[10])
    begin
        UoMReq := _UoM;
    end;
    /// <summary>
    /// Sets the Lot No. on the request page
    /// </summary>
    procedure Set_LotNo(_LotNo: Text)
    begin
        LotNoReq := _LotNo;
    end;
    /// <summary>
    /// Sets the Expiration Date on the request page
    /// </summary>
    procedure Set_ExpirationDate(_ExpirationDate: Date)
    begin
        ExpirationDateReq := _ExpirationDate;
    end;
    /// <summary>
    /// Sets the Serial No. on the request page
    /// </summary>
    procedure Set_SerialNo(_SerialNo: Text)
    begin
        SerialNoReq := _SerialNo;
    end;
    /// <summary>
    /// Sets the Package No. on the request page
    /// </summary>
    procedure Set_PackageNo(_PackageNo: Text)
    begin
        PackageNoReq := _PackageNo;
    end;
    /// <summary>
    /// Sets the No. of Copies on the request page
    /// </summary>
    /// <param name="_NoOfCopies">Please notice, that "2" copies results in 3 labels. One original and two copies. You should therefore specify "0" to get one label.</param>
    procedure Set_NoOfCopies(_NoOfCopies: Integer)
    begin
        NoOfCopiesReq := _NoOfCopies;
    end;

    var
        Mob1DInternalMobFunctions: Codeunit "MOB1D Internal MOB Functions";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobTypeHelper: Codeunit "MOB Type Helper";
        MobGs1Helper: Codeunit "MOB GS1 Helper";
        InternalAiDictionary: Dictionary of [Text, Text];
        NoOfLoops: Integer;
        NoValidReferenceErr: Label 'It was not possible to identify a valid Reference No. for Item No. %1 to be encoded in the barcode', Comment = '%1 represents Item No.', Locked = true;

    //OBS. Avoid changing protected variables to not cause errors in depending apps.
    protected var
        EncodedBarcodeText: Text;
        NoOfCopiesReq: Integer;
        BarcodeTxt: Text;
        ItemVariantCodeReq: Code[10];
        LotNoReq: Text;
        SerialNoReq: Text;
        ExpirationDateReq: Date;
        ExpirationDateTxt: Text;
        PackageNoReq: Text;
        QuantityReq: Decimal;
        QuantityTxt: Text;
        UoMReq: Code[10];

        /// <summary>
        /// This protected dictionary can be used in OnAfterAfterGetRecord to get the AIs added by Mobile WMS and any Report Extension if a different encoding is needed.
        /// It should not be used in OnBeforeAfterGetRecord as it will not be used by Mobile WMS when encoding the barcode.
        /// </summary>
        AiDictionary: Dictionary of [Text, Text];

    /* #endif */
    /* #if BC19- ##
    trigger OnPreReport()
    begin
        Error('This Mobile WMS Report is only available in BC 20 and later');
    end;
    /* #endif */
}