MakeScopePostChannel = function(room,id) {
    if (typeof App['scopePostChannel'] === "undefined") App.scopePostChannel={};
    if (typeof App.scopePostChannel[room+id] === "object") return false;

    App.scopePostChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopePostChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopePostChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopePostChannel '+room+id)},
        received: function(data) {
            for (var i = 0; i < data.html.length; i++) {
                var  type = data.type;

                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-post'),
                            element = $('body').find("[data-item-post="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-post'),
                            element = $('body').find("[data-item-post="+itemId+"]");
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-post-parent]");
                        parent.prepend(data.html[i]);
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
