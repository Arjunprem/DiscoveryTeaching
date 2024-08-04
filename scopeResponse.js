MakeScopeResponseChannel = function(room,id) {
    if (typeof App['scopeResponseChannel'] === "undefined") App.scopeResponseChannel={};
    if (typeof App.scopeResponseChannel[room+id] === "object") return false;
    App.scopeResponseChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeResponseChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeResponseChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeResponseChannel '+room+id)},
        received: function(data) {
            //console.log(data);
            for (var i = 0; i < data.html.length; i++) {
                var  type = data.type;
                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-response'),
                            element = $('body').find("[data-item-response="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-response'),
                            element = $('body').find("[data-item-response="+itemId+"]");
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-response-parent]");
                        parent.append(data.html[i]);
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