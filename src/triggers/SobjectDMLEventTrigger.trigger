trigger SobjectDMLEventTrigger on SobjectDMLEvent__e (after insert) {

SobjectDMLEventService.subscribeEvent((List<SobjectDMLEvent__e >) trigger.new);

}