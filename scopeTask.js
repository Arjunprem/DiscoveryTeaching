MakeScopeTaskChannel = function(room,id) {

    if (typeof App['scopeTaskChannel'] === "undefined") App.scopeTaskChannel={};
    if (typeof App.scopeTaskChannel[room+id] === "object") return false;

    App.scopeTaskChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeTaskChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeTaskChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeTaskChannel '+room+id)},
        received: function(data) {
            for (var i = 0; i < data.html.length; i++) {
                var  type = data.type;
                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-task'),
                            element = $('body').find("[data-item-task="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-task'),
                            element = $('body').find("[data-item-task="+itemId+"]");
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-task-parent]");
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