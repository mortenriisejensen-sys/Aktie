page 50102 "Stock List"
{
    PageType = List;
    SourceTable = "Stock Data";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "Stock Card";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Symbol"; Rec."Symbol") { ApplicationArea = All; }
                field("Price"; Rec."Price") { ApplicationArea = All; Editable = false; }
                field("PE Ratio"; Rec."PE Ratio") { ApplicationArea = All; Editable = false; }
                field("Last Updated"; Rec."Last Updated") { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(UpdateData)
            {
                Caption = 'Opdater Valgt';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                var
                    StockMgt: Codeunit "Stock Data Mgt";
                begin
                    if Rec."Symbol" = '' then
                        Error('Udfyld Symbol først.');
                    StockMgt.UpdateStockData(Rec."Symbol"); // <<— record-reference
                    CurrPage.Update();
                end;
            }
        }
    }
}
