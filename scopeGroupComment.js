MakeScopeGroupCommentChannel = function(room,id) {
    if (typeof App['scopeGroupCommentChannel'] === "undefined") App.scopeGroupCommentChannel={};
    if (typeof App.scopeGroupCommentChannel[room+id] === "object") return false;
    App.scopeGroupCommentChannel[room+id] = App.cable.subscriptions.create({
        channel: "ScopeGroupCommentChannel",
        room: room+id
    }, {
        connected: function() {console.log('connect ScopeGroupCommentChannel '+room+id)},
        disconnected: function() {console.log('disconnected ScopeGroupCommentChannel '+room+id)},
        received: function(data) {
            for (var i = 0; i < data.html.length; i++) {
                var  type = data.type;
                switch (type) {
                    case 'update':
                        var itemId = $(data.html[i]).data('item-group-comment'),
                            element = $('body').find("[data-item-group-comment="+itemId+"]");

                        element.replaceWith(data.html[i]);
                        break;
                    case 'destroy':
                        var itemId = $(data.html[i]).data('item-group-comment'),
                            element = $('body').find("[data-item-group-comment="+itemId+"]");
                        console.log(itemId);
                        element.remove();
                        break;
                    case 'new':
                        var parent = $('body').find("[data-item-groupcomment-parent]");
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