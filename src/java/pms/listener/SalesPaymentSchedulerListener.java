package pms.listener;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import pms.model.BillDAO;

/**
 * Lập lịch tự động hủy các Bill pending quá 24h.
 */
public class SalesPaymentSchedulerListener implements ServletContextListener {

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "sales-payment-scheduler");
            t.setDaemon(true);
            return t;
        });

        Runnable cancelPendingBillsTask = () -> {
            try {
                BillDAO billDAO = new BillDAO();
                int affected = billDAO.cancelPendingBillsOlderThan24h();
                if (affected > 0) {
                    System.out.println("[SalesPaymentScheduler] Auto-cancelled pending bills: " + affected);
                }
            } catch (Exception e) {
                System.err.println("[SalesPaymentScheduler] Error while auto-cancelling pending bills: " + e.getMessage());
            }
        };

        // Chạy lần đầu sau 60s, sau đó lặp mỗi 5 phút
        scheduler.scheduleAtFixedRate(cancelPendingBillsTask, 60, 300, TimeUnit.SECONDS);
        System.out.println("[SalesPaymentScheduler] Started (auto-cancel pending bills > 24h).");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdown();
            try {
                if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow();
                }
            } catch (InterruptedException e) {
                scheduler.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
        System.out.println("[SalesPaymentScheduler] Stopped.");
    }
}
