package ochaloup;

/**
 * @author Ondrej Chaloupka
 */
public class NodeNameGetter {

    private NodeNameGetter() {
    }

    public static String getNodeName() {
        String nodename = System.getProperty("jboss.node.name");
        return nodename;
    }
}
