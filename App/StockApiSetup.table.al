table 50101 "Stock API Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "API Key"; Text[100]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
