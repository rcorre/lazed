module events;

import entitysysd;
import allegro5.allegro;

@event:

struct KeyboardEvent {
    ALLEGRO_EVENT_TYPE type;
    int key;
}
