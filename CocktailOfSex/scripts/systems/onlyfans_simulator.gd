extends Node
class_name OnlyFansSimulator

var body: CocktailBody
var economy: SexEconomySystem

var channel_name: String = ""
var channel_description: String = ""
var subscriber_count: int = 0
var free_subscribers: int = 0
var premium_subscribers: int = 0
var subscription_price: float = 9.99

var content_posts: Array[Dictionary] = []
var scheduled_posts: Array[Dictionary] = []
var messages: Array[Dictionary] = []

var total_likes: int = 0
var total_views: int = 0
var engagement_rate: float = 0.0

var is_verified: bool = false
var verification_pending: bool = false

signal new_subscriber(type: String)
signal subscriber_left(type: String)
signal post_published(post: Dictionary)
signal tip_received(tipper: String, amount: float)
signal message_received(sender: String, content: String)

func _init(_body: CocktailBody, _economy: SexEconomySystem):
    body = _body
    economy = _economy
    channel_name = body.body_name + "'s Exclusive Content"

func create_post(content_type: String, description: String, is_free: bool = false, price: float = 0.0):
    var post = {
        "id": content_posts.size() + 1,
        "type": content_type,
        "description": description,
        "is_free": is_free,
        "price": price,
        "likes": 0,
        "views": 0,
        "comments": [],
        "timestamp": Time.get_ticks_msec()
    }
    content_posts.append(post)
    post_published.emit(post)
    return post

func gain_subscriber(is_premium: bool = false):
    subscriber_count += 1
    if is_premium:
        premium_subscribers += 1
        economy.add_money(subscription_price * 0.7, "onlyfans_premium")
    else:
        free_subscribers += 1
    new_subscriber.emit("premium" if is_premium else "free")

func lose_subscriber(is_premium: bool = false):
    if subscriber_count > 0:
        subscriber_count -= 1
        if is_premium:
            premium_subscribers = max(0, premium_subscribers - 1)
        else:
            free_subscribers = max(0, free_subscribers - 1)
        subscriber_left.emit("premium" if is_premium else "free")

func send_private_message(subscriber_name: String, message_content: String, price: float = 0.0):
    var msg = {
        "to": subscriber_name,
        "content": message_content,
        "price": price,
        "is_read": false,
        "timestamp": Time.get_ticks_msec()
    }
    messages.append(msg)
    if price > 0:
        economy.add_money(price, "private_message")
    return msg

func receive_tip(tipper_name: String, amount: float):
    economy.add_money(amount * 0.8, "onlyfans_tip")
    tip_received.emit(tipper_name, amount)

func get_channel_stats() -> Dictionary:
    return {
        "name": channel_name,
        "subscribers": subscriber_count,
        "premium": premium_subscribers,
        "free": free_subscribers,
        "total_posts": content_posts.size(),
        "total_likes": total_likes,
        "total_views": total_views,
        "engagement": engagement_rate,
        "verified": is_verified
    }
