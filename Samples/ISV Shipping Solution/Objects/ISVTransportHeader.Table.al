table 62201 "ISV Transport Header"
{
    Caption = 'ISV Transport Header';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; "Warehouse Shipment No."; Code[20])
        {
            Caption = 'Warehouse Shipment No.';
        }
        field(10; "Delivery Name"; Text[100])
        {
            Caption = 'Delivery Name';
        }
        field(11; "Delivery Address"; Text[100])
        {
            Caption = 'Delivery Address';
        }
        field(12; "Delivery Post Code"; Code[20])
        {
            Caption = 'Delivery Post Code';
        }
        field(13; "Delivery City"; Text[100])
        {
            Caption = 'Delivery City';
        }
        field(14; "Delivery Country/Region Code"; Code[10])
        {
            Caption = 'Delivery Country/Region Code';
        }
        field(15; "Transport Booked"; Boolean)
        {
            Caption = 'Transport Booked';
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    procedure CreateTransportDocument(var _WhseShipmentHeader: Record "Warehouse Shipment Header"): Record "ISV Transport Header"
    var
        ISVTransportHeader: Record "ISV Transport Header";
        CompanyInformation: Record "Company Information";
    begin
        ISVTransportHeader."No." := GetNextDocNo();
        ISVTransportHeader."Warehouse Shipment No." := _WhseShipmentHeader."No.";

        CompanyInformation.Get();
        ISVTransportHeader."Delivery Name" := CompanyInformation.Name;
        ISVTransportHeader."Delivery Address" := CompanyInformation.Address;
        ISVTransportHeader."Delivery Post Code" := CompanyInformation."Post Code";
        ISVTransportHeader."Delivery City" := CompanyInformation.City;
        ISVTransportHeader."Delivery Country/Region Code" := CompanyInformation."Country/Region Code";
        ISVTransportHeader.Insert();

        exit(ISVTransportHeader);
    end;

    procedure BookAndPrint()
    begin

        // Book Transport
        Rec."Transport Booked" := true;
        Rec.Modify();

        // Call Shipment Label
        // PrintQueue to use = Rec."Print Queue"
        // Add custom Print logic..
    end;

    local procedure GetNextDocNo(): Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        exit(NoSeriesManagement.GetNextNo('P-ORD-D', WorkDate(), true));  // Cronus Demo Data
    end;
}
