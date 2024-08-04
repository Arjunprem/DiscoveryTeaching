MakePostChannel = function(room,id) {
    if (typeof App['post'] === "undefined") App.post={};
    App.post[room+id] = App.cable.subscriptions.create({
        channel: "PostChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect PostChannel'+room+id)},
        disconnected: function() {console.log('disconnected PostChannel'+room+id)},
        received: function(data) {
            return $(".postsCount_"+id).html(data.postsCount);
        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};
