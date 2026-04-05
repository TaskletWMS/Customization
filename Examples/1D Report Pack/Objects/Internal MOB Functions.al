codeunit 81272 "MOB1D Internal MOB Functions"
{
    var
        MobSetup: Record "MOB Setup";
        MobTypeHelper: Codeunit "MOB Type Helper";
        TooManyDecimalsErr: Label 'The value is limited to 5 decimals (%1).', Comment = '%1 is value';
        TooManySignificantDigitsErr: Label 'The value is limited to 6 significant digits (%1).', Comment = '%1 is value';

    internal procedure GetNextLicensePlateNo(_ModifySeries: Boolean): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        MobSetup.Get();
        MobSetup.TestField("LP Number Series");

        if _ModifySeries then
            exit(NoSeries.GetNextNo(MobSetup."LP Number Series", WorkDate(), false))
        else
            exit(NoSeries.PeekNextNo(MobSetup."LP Number Series", WorkDate()));
    end;

    internal procedure QuantityTransformedToAI310n(_QuantityPerLabel: Decimal; var _Ai310n: Text[1]; var _Ai310Qty: Text) Success: Boolean
    var
        DecimalPart: Text;
        IntegerPart: Text;
    begin
        if _QuantityPerLabel <= 0 then
            exit(false);

        IntegerPart := DecimalGetInteger(_QuantityPerLabel);
        DecimalPart := DecimalGetDecimals(_QuantityPerLabel);

        if DecimalPart = '' then
            exit(false); // No decimal: No need to use Ai 310n

        if StrLen(DecimalPart) > 5 then
            Error(TooManyDecimalsErr, _QuantityPerLabel); // Max 5 decimals

        // Encode AI 310n. Example: 2 decimals is "3102"
        _Ai310n := Format(StrLen(DecimalPart));

        // Encode barcode quantity. Example: "1,23" becomes "000123"
        _Ai310Qty := IntegerPart + DecimalPart;
        _Ai310Qty := _Ai310Qty.TrimStart('0').PadLeft(6, '0');
        if StrLen(_Ai310Qty) <> 6 then
            Error(TooManySignificantDigitsErr, _QuantityPerLabel);

        exit(true);
    end;

    internal procedure DecimalGetDecimals(_Decimal: Decimal): Text
    begin
        exit(CopyStr(Format(_Decimal, 0, '<Decimals>'), 2)); // Copy "123" from "0.123"
    end;

    internal procedure DecimalGetInteger(_Decimal: Decimal): Text
    begin
        exit(Format(_Decimal, 0, '<Integer>'));
    end;

    internal procedure ServiceHeaderShipTo(var _AddrArray: array[8] of Text[100]; var _ServiceHeader: Record "Service Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        ServiceFormatAddress.ServiceHeaderShipTo(_AddrArray, _ServiceHeader);
    end;

    internal procedure CopyTrackingToMobTrackingSetup(_MobLicensePlateContent: Record "MOB License Plate Content"; var _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _MobTrackingSetup."Serial No." := _MobLicensePlateContent."Serial No.";
        _MobTrackingSetup."Lot No." := _MobLicensePlateContent."Lot No.";
        _MobTrackingSetup."Package No." := _MobLicensePlateContent."Package No.";
    end;

    procedure GetBarcodeText(_AiDictionary: Dictionary of [Text, Text]): Text
    var
        BarcodeTxtBuilder: TextBuilder;
        AiKey: Text;
        FNC1: Text[1];
    begin
        FNC1[1] := 29;

        foreach AiKey in _AiDictionary.Keys() do
            BarcodeTxtBuilder.Append('(' + Format(AiKey) + ')' + _AiDictionary.Get(AiKey));

        // If no Ai to encode, try use the SimpleTextToEncode
        // if BarcodeTxtBuilder.ToText() = '' then
        //     BarcodeTxtBuilder.Append(SimpleTextToEncode);

        exit(BarcodeTxtBuilder.ToText());
    end;

    procedure GetEncodedBarcodeText(_BarcodeFontProvider: Interface "Barcode Font Provider"; BarcodeSymbology: Enum "Barcode Symbology"; _AiDictionary: Dictionary of [Text, Text]): Text
    var
        BarcodeTxtBuilder: TextBuilder;
        AiKey: Text;
        IDAutomationFNC1: Text[1];
    begin
        IDAutomationFNC1[1] := 202; // FNC1 character for IDAutomation fonts - used both as a separator between AI values and to indicate the start of the barcode when encoding GS1 barcodes without parentheses

        foreach AiKey in _AiDictionary.Keys() do
            BarcodeTxtBuilder.Append(IDAutomationFNC1 + Format(AiKey) + _AiDictionary.Get(AiKey));

        exit(_BarcodeFontProvider.EncodeFont(BarcodeTxtBuilder.ToText(), BarcodeSymbology));
    end;
}
