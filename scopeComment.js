MakeScopeCommentChannel = function(room,id) {
    if (typeof App['scopeCommentChannel'] === "undefined") App.scopeCommentChannel={};
    if (typeof App.scopeCommentChannel[room+id] === "object") return false;
    App.scopeCommentChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeCommentChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeCommentChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeCommentChannel '+room+id)},
        received: function(data) {
            for (var i = 0; i < data.html.length; i++) {
                var  type = data.type;
                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-comment'),
                            element = $('body').find("[data-item-comment="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-comment'),
                            element = $('body').find("[data-item-comment="+itemId+"]");
                        console.log(itemId);
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-comment-parent]");
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
