codeunit 60800 CustomItemImageHandler
{
    //=================================================================================================
    // This codeunit demonstrates how to use event subscribers to customize the process of specifying and retrieving item images in Mobile WMS.
    //
    // By subscribing to the relevant events in the "MOB WMS Media" codeunit, you can provide custom logic to determine the image ID for an item
    // based on its number and variant, as well as handle the retrieval of the image data when requested by the system.
    //
    // This example uses OnBefore and OnAfter event subscribers for the 'OnGetItemImageID' procedure to show how you can either
    // override the image ID before the default logic runs or modify it after the default logic has executed.
    // You can choose either approach based on your specific requirements.
    //
    // It also shows how to handle the GetMedia request by subscribing to the 'OnGetMedia_OnBeforeAddImageToMedia' event,
    // allowing you to provide the image data as Base64 directly from an external source, such as a URL.
    // 
    // The example focuses on an item called 'SPACESHIP' with two variants: 'GREEN' and 'ORANGE'. Depending on the variant, a different image will be returned.
    //=================================================================================================

    //=================================================================================================
    // SPECIFYING THE ITEM IMAGE ID - OnBeforeGetItemImageID 
    // Set ItemImageID for item SPACESHIP and variant GREEN before default logic runs, effectively overriding any other logic for this variant.
    //=================================================================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", OnBeforeGetItemImageID, '', false, false)]
    local procedure Example_OnBeforeGetItemImageID(var _ItemNo: Code[20]; var _VariantCode: Code[10]; var _ItemImageID: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;
        if _ItemNo <> 'SPACESHIP' then
            exit;
        if _VariantCode <> 'GREEN' then
            exit;

        _ItemImageID := BuildCustomItemImageID(_ItemNo, _VariantCode);
        if _ItemImageID <> '' then
            _IsHandled := true;
    end;

    //=================================================================================================
    // SPECIFYING THE ITEM IMAGE ID - OnAfterGetItemImageID 
    // Set ItemImageID for item SPACESHIP and variant ORANGE after default logic runs, allowing you to modify the image ID if needed.
    //=================================================================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", OnAfterGetItemImageID, '', false, false)]
    local procedure Example_OnAfterGetItemImageID(var _ItemNo: Code[20]; var _VariantCode: Code[10]; var _ItemImageID: Text)
    var
        CustomImageID: Text;
    begin
        if _ItemNo <> 'SPACESHIP' then
            exit;
        if _VariantCode <> 'ORANGE' then
            exit;

        CustomImageID := BuildCustomItemImageID(_ItemNo, _VariantCode);
        if CustomImageID <> '' then
            _ItemImageID := CustomImageID;
    end;

    //=================================================================================================
    // RETURNING THE ITEM IMAGE - OnGetMedia_OnBeforeAddImageToMedia
    // Handle the GetMedia request for our custom item images, allowing you to provide the image data as Base64 directly from an external source.
    //=================================================================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", OnGetMedia_OnBeforeAddImageToMedia, '', false, false)]
    local procedure Example_OnGetMedia_OnBeforeAddImageToMedia(_MediaID: Text; _ScreenHeight: Integer; _ScreenWidth: Integer; var _Base64Media: Text; var _IsHandled: Boolean)
    var
        ItemNo: Code[20];
        VariantCode: Code[10];
        VersionToken: Text;
    begin
        if _IsHandled then
            exit;

        if not CanHandleMediaId(_MediaID, ItemNo, VariantCode, VersionToken) then
            exit; // GetMedia is shared for multiple media types, so only handle IDs with our item-image prefix.

        _Base64Media := GetItemImageAsBase64(ItemNo, VariantCode, VersionToken);
        if _Base64Media <> '' then
            _IsHandled := true;
    end;

    // Builds the image ID by fetching the image and using its content hash as the version token.
    // See the README for a discussion of this approach and alternatives.
    local procedure BuildCustomItemImageID(ItemNo: Code[20]; VariantCode: Code[10]): Text
    var
        ImageUrl: Text;
        Base64Image: Text;
        VersionToken: Text;
        MediaIdLbl: Label 'ItemImageFromUrl_%1_%2_%3', Locked = true; // Replace 'ItemImageFromUrl' with a prefix unique to your solution, so you know when to handle it. Format: <MyUniquePrefix>_<ItemNo>_<VariantCode>_<VersionToken>.
    begin
        ImageUrl := GetImageUrl(ItemNo, VariantCode);
        if ImageUrl = '' then
            exit('');

        Base64Image := RetrieveAndConvertImage(ImageUrl);
        if Base64Image = '' then
            exit('');

        VersionToken := GetVersionTokenFromBase64(Base64Image);
        if VersionToken = '' then
            exit('');

        exit(StrSubstNo(MediaIdLbl, ItemNo, VariantCode, VersionToken));
    end;

    // Decodes the MediaID to determine if it's an ID we should handle, and to extract the ItemNo, VariantCode, and VersionToken for retrieving the correct image.
    local procedure CanHandleMediaId(MediaID: Text; var ItemNo: Code[20]; var VariantCode: Code[10]; var VersionToken: Text): Boolean
    var
        MediaIDParts: List of [Text];
        PartValue: Text;
    begin
        MediaIDParts := MediaID.Split('_');
        if MediaIDParts.Count() <> 4 then // Our custom MediaID should have 4 parts
            exit(false);

        MediaIDParts.Get(1, PartValue);
        if PartValue <> 'ItemImageFromUrl' then // The first part should be our unique prefix to ensure we only handle relevant MediaIDs
            exit(false);

        MediaIDParts.Get(2, PartValue);
        ItemNo := CopyStr(PartValue, 1, MaxStrLen(ItemNo));

        MediaIDParts.Get(3, PartValue);
        VariantCode := CopyStr(PartValue, 1, MaxStrLen(VariantCode));

        MediaIDParts.Get(4, VersionToken);

        exit(true);
    end;

    // Retrieves the image from the external source, converts it to Base64, and verifies the content matches the version token to ensure cache validity.
    local procedure GetItemImageAsBase64(ItemNo: Code[20]; VariantCode: Code[10]; VersionToken: Text): Text
    var
        ImageUrl: Text;
        Base64Image: Text;
    begin
        ImageUrl := GetImageUrl(ItemNo, VariantCode);
        if ImageUrl = '' then
            exit('');

        Base64Image := RetrieveAndConvertImage(ImageUrl);
        if Base64Image = '' then
            exit('');

        if GetVersionTokenFromBase64(Base64Image) <> VersionToken then
            exit('');

        exit(Base64Image);
    end;

    // Construct the image URL from the item number and variant code.
    // This assumes the external storage uses a predictable naming convention: {ItemNo}_{VariantCode}.png
    // See the README for a discussion of this approach and alternatives.
    local procedure GetImageUrl(ItemNo: Code[20]; VariantCode: Code[10]): Text
    var
        ImageUrlLbl: Label 'https://raw.githubusercontent.com/TaskletWMS/Customization/jbj-april2026/Examples/Item%20Image%20From%20Alternative%20Storage/media/%1.png', Locked = true;
        ItemWithVariantLbl: Label '%1_%2', Locked = true;
    begin
        if ItemNo = '' then
            exit('');

        if VariantCode <> '' then
            exit(StrSubstNo(ImageUrlLbl, StrSubstNo(ItemWithVariantLbl, ItemNo, VariantCode)));
        exit(StrSubstNo(ImageUrlLbl, ItemNo));
    end;

    local procedure RetrieveAndConvertImage(ImageUrl: Text): Text
    var
        Content: HttpContent;
    begin
        if not GetHttpContent(ImageUrl, Content) then
            exit('');
        exit(ConvertContentToBase64(Content));
    end;

    local procedure GetHttpContent(ImageUrl: Text; var Content: HttpContent): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
    begin
        if not HttpClient.Get(ImageUrl, HttpResponseMessage) then
            exit(false);
        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);
        Content := HttpResponseMessage.Content();
        exit(true);
    end;

    local procedure ConvertContentToBase64(var Content: HttpContent): Text
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        ImageInStream: InStream;
    begin
        if not Content.ReadAs(ImageInStream) then
            exit('');
        exit(MobBase64Convert.ToBase64(ImageInStream));
    end;

    local procedure GetVersionTokenFromBase64(Base64Image: Text): Text
    var
        CryptographyMgmt: Codeunit "Cryptography Management";
    begin
        // SHA-256 (algorithm 2) produces a 64-character hex string, which is unnecessarily long for a cache key.
        // We truncate to 8 characters — the collision probability is negligible for this use case,
        // while keeping the media ID short and readable.
        exit(CopyStr(CryptographyMgmt.GenerateHash(Base64Image, 2), 1, 8));
    end;
}