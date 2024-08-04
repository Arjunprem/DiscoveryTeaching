MakeScopeActivityChannel = function(room,id) {

    if (typeof App['scopeActivityChannel'] === "undefined") App.scopeActivityChannel={};
    if (typeof App.scopeActivityChannel[room+id] === "object") return false;
    App.scopeActivityChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeActivityChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeActivityChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeActivityChannel '+room+id)},
        received: function(data) {
            console.log(data);
            for (var i = 0; i < data.html.length; i++) {

                var type = data.type;

                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-activity'),
                            element = $('body').find("[data-item-activity="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-activity'),
                            element = $('body').find("[data-item-activity="+itemId+"]");
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-activity-parent]");
                        parent.prepend(data.html[0]);
                        break;
                    default:
                        console.error('type not found')
                }
            }



        },
        init: function(message, room) {
            return this.perform('init', {
                message: message,
                room: room+id
            });
        }
    });
};