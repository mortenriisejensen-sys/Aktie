codeunit 50100 "Stock Data Mgt"
{
    procedure UpdateStockData(Symbol: Code[20])
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        APISetup: Record "Stock API Setup";
        StockRec: Record "Stock Data";
        APIUrl: Text;
        APIKey: Text;

        InStr: InStream;
        RootTok: JsonToken;
        RootObj: JsonObject;
        GlobalQuoteTok: JsonToken;
        GlobalQuoteObj: JsonObject;
        PriceTok: JsonToken;

        PriceVal: Decimal;
        PEVal: Decimal;
    begin
        if not APISetup.Get('SETUP') then
            Error('API Setup mangler. Åbn "Stock API Setup" og udfyld API Key.');

        APIKey := APISetup."API Key";
        if APIKey = '' then
            Error('API Key er tom. Udfyld i "Stock API Setup".');

        APIUrl := StrSubstNo(
            'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=%1&apikey=%2',
            Symbol, APIKey);

        if not Client.Get(APIUrl, Response) then
            Error('Kunne ikke kontakte API.');

        if not Response.IsSuccessStatusCode() then
            Error('API fejl: %1', Response.HttpStatusCode());

        // Læs som InStream og parse til JsonToken/JsonObject
        Response.Content.ReadAs(InStr);
        RootTok.ReadFrom(InStr);
        RootObj := RootTok.AsObject();

        if not RootObj.Get('Global Quote', GlobalQuoteTok) then
            Error('Ugyldigt svar fra API (mangler "Global Quote").');

        GlobalQuoteObj := GlobalQuoteTok.AsObject();

        // Hent pris
        if GlobalQuoteObj.Get('05. price', PriceTok) then
            PriceVal := EvaluateDecimal(PriceTok)
        else
            PriceVal := 0;

        // Global Quote har ikke P/E → sæt 0 (eller hent via OVERVIEW i udvidelse)
        PEVal := 0;

        // Gem i tabel
        if StockRec.Get(Symbol) then begin
            StockRec."Price" := PriceVal;
            StockRec."PE Ratio" := PEVal;
            StockRec."Last Updated" := CurrentDateTime();
            StockRec.Modify();
        end else begin
            StockRec.Init();
            StockRec."Symbol" := Symbol;
            StockRec."Price" := PriceVal;
            StockRec."PE Ratio" := PEVal;
            StockRec."Last Updated" := CurrentDateTime();
            StockRec.Insert();
        end;
    end;

    local procedure EvaluateDecimal(ValueTok: JsonToken): Decimal
    var
        Txt: Text;
        DecVal: Decimal;
    begin
        if ValueTok.IsValue() then
            Txt := ValueTok.AsValue().AsText();

        if (Txt <> '') and Evaluate(DecVal, Txt) then
            exit(DecVal)
        else
            exit(0);
    end;
}
