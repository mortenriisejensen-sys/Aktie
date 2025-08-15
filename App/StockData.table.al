table 50100 "Stock Data"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Symbol"; Code[20]) { DataClassification = CustomerContent; }
        field(2; "Price"; Decimal) { DataClassification = CustomerContent; }
        field(3; "PE Ratio"; Decimal) { DataClassification = CustomerContent; }
        field(4; "Last Updated"; DateTime) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Symbol") { Clustered = true; }
    }
}
