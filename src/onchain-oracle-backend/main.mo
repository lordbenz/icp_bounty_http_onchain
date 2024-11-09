import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";

import Types "Types";

actor {

    //  [
    //     [
    //         1641081600, <-- start timestamp
    //         47400, <-- lowest price during time range
    //         47770.37, <-- highest price during range
    //         47733.43, <-- price at open
    //         47637.43, <-- price at close
    //         455.5481161 <-- volume of BTC traded
    //     ],
    // ]

    public func get_btc_usd_exchange() : async Text {

        // DECLARE MANAGEMENT CANISTER
        let ic : Types.IC = actor ("aaaaa-aa");

        //2. SETUP ARGUMENTS FOR HTTP GET request

        // 2.1 Setup the URL and its query parameters
        let host : Text = "api.exchange.coinbase.com";
        let url = "https://" # host # "/products/BTC-USD/candles?granularity=3600&start=2022-01-01T00:00:00Z&end=2022-01-02T00:00:00Z";

        // 2.2 prepare headers for the system http_request call
        let request_headers = [
            { name = "Host"; value = host # ":443" },
            { name = "User-Agent"; value = "exchange_rate_canister" },
        ];

        // 2.2.1 Transform context
        let transform_context : Types.TransformContext = {
            function = transform;
            context = Blob.fromArray([]);
        };

        // 2.3 The HTTP request
        let http_request : Types.HttpRequestArgs = {
            url = url;
            max_response_bytes = null; //optional for request
            headers = request_headers;
            body = null; //optional for request
            method = #get;
            transform = ?transform_context;
        };

        //3. ADD CYCLES TO PAY FOR HTTP REQUEST
        Cycles.add(20_949_972_000);

        //4. MAKE HTTP REQUEST AND WAIT FOR RESPONSE
        let http_response : Types.HttpResponsePayload = await ic.http_request(http_request);

        //5. DECODE THE RESPONSE

        //As per the type declarations in `src/Types.mo`, the BODY in the HTTP response
        //comes back as [Nat8s] (e.g. [2, 5, 12, 11, 23]). Type signature:

        //public type HttpResponsePayload = {
        //     status : Nat;
        //     headers : [HttpHeader];
        //     body : [Nat8];
        // };

        //You need to decode that [Nat8] array that is the body into readable text.
        //To do this, you:
        //  1. Convert the [Nat8] into a Blob
        //  2. Use Blob.decodeUtf8() method to convert the Blob to a ?Text optional
        //  3. You use a switch to explicitly call out both cases of decoding the Blob into ?Text
        let response_body : Blob = Blob.fromArray(http_response.body);
        let decoded_text : Text = switch (Text.decodeUtf8(response_body)) {
            case (null) { "No value returned" };
            case (?y) { y };
        };

        //6. RETURN RESPONSE OF THE BODY
        //The API response will looks like this:

        // ("[[1641081600,47400,47770.37,47733.43,47637.43,455.5481161]]")

        //Which can be formatted as this
        //  [
        //     [
        //         1641081600, <-- start/timestamp
        //         47400, <-- low
        //         47770.37, <-- high
        //         47733.43, <-- open
        //         47637.43, <-- close
        //         455.5481161 <-- volume
        //     ],
        // ]
        decoded_text;
    };

    //7. CREATE TRANSFORM FUNCTION
    public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
        let transformed : Types.CanisterHttpResponsePayload = {
            status = raw.response.status;
            body = raw.response.body;
            headers = [
                {
                    name = "Content-Security-Policy";
                    value = "default-src 'self'";
                },
                { name = "Referrer-Policy"; value = "strict-origin" },
                { name = "Permissions-Policy"; value = "geolocation=(self)" },
                {
                    name = "Strict-Transport-Security";
                    value = "max-age=63072000";
                },
                { name = "X-Frame-Options"; value = "DENY" },
                { name = "X-Content-Type-Options"; value = "nosniff" },
            ];
        };
        transformed;
    };
};
