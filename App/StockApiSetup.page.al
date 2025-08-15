page 50101 "Stock API Setup"
{
    PageType = Card;
    SourceTable = "Stock API Setup";
    ApplicationArea = All;
    Caption = 'Stock API Setup';
    UsageCategory = Administration; // ← gør den søgbar

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Primary Key"; Rec."Primary Key")
                {
                    ApplicationArea = All;
                    Editable = false; // eller Visible = false;
                }
                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get('SETUP') then begin
            Rec.Init();
            Rec."Primary Key" := 'SETUP';
            Rec.Insert(true);
            CurrPage.Update();
        end;
    end;
}
