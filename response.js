MakeResponseChannel = function(room,id) {
    if (typeof App['response'] === "undefined") App.response={};
    App.response[room+id] = App.cable.subscriptions.create({
        channel: "ResponseChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ResponseChannel'+room+id)},
        disconnected: function() {console.log('disconnected ResponseChannel'+room+id)},
        received: function(data) {
            return $("#responsesCount_"+data.question_id).html(data.responsesCount + " responses&nbsp;&nbsp;");
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};