import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";
import Types "Types";
import { print } = "mo:base/Debug";
import { recurringTimer } = "mo:base/Timer";

actor {

    let fetchInterval = 60; // Duration in seconds for the reminder

    var latestData : Text = ""; // Variable to store the latest fetched data
    // var startTime : Text = ""; // Variable to store the start time
    // var endTime : Text = ""; // Variable to store the end time

    // This function will fetch the data and store it in latestData
    private func fetchData() : async () {
        // DECLARE MANAGEMENT CANISTER
        let ic : Types.IC = actor ("aaaaa-aa");

        // Setup the URL with stored startTime and endTime
        let host : Text = "api.exchange.coinbase.com";
        // Replace the existing `let url` line in `fetchData` function with this:
        let url = "https://" # host # "/products/BTC-USD/candles?granularity=60&limit=60";


        // Prepare headers for the system http_request call
        let request_headers = [
            { name = "Host"; value = host # ":443" },
            { name = "User-Agent"; value = "exchange_rate_canister" },
        ];

        // Transform context
        let transform_context : Types.TransformContext = {
            function = transform;
            context = Blob.fromArray([]);
        };

        // The HTTP request
        let http_request : Types.HttpRequestArgs = {
            url = url;
            max_response_bytes = null; // Optional for request
            headers = request_headers;
            body = null; // Optional for request
            method = #get;
            transform = ?transform_context;
        };

        // Add cycles to pay for HTTP request
        Cycles.add(20_949_972_000);

        // Make HTTP request and wait for response
        let http_response : Types.HttpResponsePayload = await ic.http_request(http_request);

        // Decode the response
        let response_body : Blob = Blob.fromArray(http_response.body);
        let decoded_text : Text = switch (Text.decodeUtf8(response_body)) {
            case (null) { "No value returned" };
            case (?y) { y };
        };

        // Store the response in latestData
        latestData := decoded_text;
    };

    // This function sets up the initial timer and stores the start and end times
    // public func setup(startTimeParam : Text, endTimeParam : Text) : async () {
    public func setup() : async () {
        // startTime := startTimeParam;
        // endTime := endTimeParam;
        await fetchData();
        ignore recurringTimer<system>(#seconds(fetchInterval), fetchData);
    };

    // This function returns the latest fetched data
    // [Query call]

    public query func get_latest_data() : async Text {
        return latestData;
    };

    // The transform function remains the same
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
