MakeGroupChannel = function(room,id) {
    if (typeof App['group'] === "undefined") App.group={};
    App.group[room+id] = App.cable.subscriptions.create({
        channel: "GroupChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect GroupChannel'+room+id)},
        disconnected: function() {console.log('disconnected GroupChannel'+room+id)},
        received: function(data) {
             $("#GroupCount_"+id).html(data.responsesCount);
             $('#GroupResponsesTab_'+id).css('color','red');
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};