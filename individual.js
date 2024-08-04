MakeIndividualChannel = function(room,id) {
    if (typeof App['individual'] === "undefined") App.individual={};
    App.individual[room+id] = App.cable.subscriptions.create({
        channel: "IndividualChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect IndividualChannel'+room+id)},
        disconnected: function() {console.log('disconnected IndividualChannel'+room+id)},
        received: function(data) {
            $("#IndividualCount_"+id).html(data.responsesCount);
            $('#IndividualResponsesTab_'+id).css('color','red');
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};