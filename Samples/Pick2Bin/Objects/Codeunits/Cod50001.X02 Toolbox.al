codeunit 50001 "X02 Toolbox"
{
    // Misc. helper functions

    /// <summary>
    /// Convert Decimal to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    internal procedure Decimal2TextAsDisplayFormat(_Decimal: Decimal; _BlankZero: Boolean): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        if _Decimal = 0 then
            if _BlankZero then
                exit(' ') // Space is intentional
            else
                exit('0');

        // Uses DotNet String.Format. See https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-numeric-format-strings#SpecifierD
        exit(TypeHelper.FormatDecimal(_Decimal, '0.################', TypeHelper.LanguageIDToCultureName(GlobalLanguage()))); //'0.################' = Any value without 1000-separator, limited to max 16 decimal places
    end;

    /// <summary>
    /// Convert Decimal to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    internal procedure Decimal2TextAsDisplayFormat(_Decimal: Decimal): Text
    begin
        exit(Decimal2TextAsDisplayFormat(_Decimal, false));
    end;
    /// <summary>
    /// Converts Date to Sql sort order Code (format by YYYYMMDD)
    /// </summary>

    internal procedure GetItemDescriptions(_ItemNo: Code[20]; _VariantCode: Code[10]) ReturnDescription: Text
    var
        Item: Record "Item";
        ItemVariant: Record "Item Variant";
        SeparatorText: Text;
    begin
        SeparatorText := ' ';

        if _VariantCode <> '' then
            if ItemVariant.Get(_ItemNo, _VariantCode) then
                ReturnDescription := JoinText(ItemVariant.Description, ItemVariant."Description 2", SeparatorText);

        // Fallback if called with blank VariantCode or no description is entered in ItemVariant
        if ReturnDescription = '' then
            if Item.Get(_ItemNo) then
                ReturnDescription := JoinText(Item.Description, Item."Description 2", SeparatorText);

        ReturnDescription := ReturnDescription.TrimStart(SeparatorText);
        exit(ReturnDescription);
    end;

    // Based on dotnet String.Join
    internal procedure JoinText(_Text1: Text; _Text2: Text; _Separator: Text) ReturnText: Text
    begin
        ReturnText := _Text1 + _Separator + _Text2;
        ReturnText := ReturnText.TrimStart(_Separator);
        ReturnText := ReturnText.TrimEnd(_Separator);
        exit(ReturnText);
    end;

}
