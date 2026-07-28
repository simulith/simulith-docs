import java.util.HashMap;
import java.util.Map;

/** Minimal Java Lambda handler for Simulith CLI demo (SML-166+). */
public class App {
  public Map<String, Object> handleRequest(Map<String, Object> event) {
    Map<String, Object> out = new HashMap<>();
    String greeting = System.getenv("GREETING");
    if (greeting == null || greeting.isEmpty()) {
      greeting = "hello-from-java";
    }
    out.put("greeting", greeting);
    out.put("echo", event != null ? event : new HashMap<>());
    return out;
  }
}
