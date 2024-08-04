MakeShowChannel = function(room,id) {
    if (typeof App['show'] === "undefined") App.show={};
    App.group[room+id] = App.cable.subscriptions.create({
        channel: "ShowChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ShowChannel'+room+id)},
        disconnected: function() {console.log('disconnected ShowChannel'+room+id)},
        received: function(data) {
            $("#summaryCount_"+id).html(data.responsesCount);
            $('#responsesTab_'+id).css('color','red');
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};