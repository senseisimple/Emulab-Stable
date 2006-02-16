import java.util.*;


public class Editor extends javax.swing.JFrame {
    
    /** Creates new form Editor */
    public Editor() {
        initComponents();
    }
    
    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc=" Generated Code ">//GEN-BEGIN:initComponents
    private void initComponents() {
        java.awt.GridBagConstraints gridBagConstraints;

        controlPanel = new javax.swing.JPanel();
        newSplineButton = new javax.swing.JButton();
        editSpline = new javax.swing.JButton();
        deleteSplineButton = new javax.swing.JButton();
        drawPanel = new DrawPanel();

        getContentPane().setLayout(new java.awt.GridBagLayout());

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        controlPanel.setLayout(new java.awt.GridBagLayout());

        newSplineButton.setText("Add Spline");
        newSplineButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                newSplineButtonActionPerformed(evt);
            }
        });

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.NORTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(2, 2, 2, 2);
        controlPanel.add(newSplineButton, gridBagConstraints);

        editSpline.setText("Edit Spline");
        editSpline.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                editSplineActionPerformed(evt);
            }
        });

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.NORTH;
        gridBagConstraints.insets = new java.awt.Insets(2, 2, 2, 2);
        controlPanel.add(editSpline, gridBagConstraints);

        deleteSplineButton.setText("Delete Spline");
        deleteSplineButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                deleteSplineButtonActionPerformed(evt);
            }
        });

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.insets = new java.awt.Insets(2, 2, 2, 2);
        controlPanel.add(deleteSplineButton, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.NORTH;
        gridBagConstraints.weighty = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(1, 1, 1, 1);
        getContentPane().add(controlPanel, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.WEST;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(1, 1, 1, 1);
        getContentPane().add(drawPanel, gridBagConstraints);

        pack();
    }
    // </editor-fold>//GEN-END:initComponents

    private void deleteSplineButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_deleteSplineButtonActionPerformed
        drawPanel.setTool(DrawPanel.TOOL_DELETE_SPLINE);
    }//GEN-LAST:event_deleteSplineButtonActionPerformed

    private void editSplineActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_editSplineActionPerformed
        drawPanel.setTool(DrawPanel.TOOL_EDIT_SPLINE);
    }//GEN-LAST:event_editSplineActionPerformed

    private void newSplineButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_newSplineButtonActionPerformed
        drawPanel.setTool(DrawPanel.TOOL_DRAW_SPLINE);
    }//GEN-LAST:event_newSplineButtonActionPerformed
        
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new Editor().setVisible(true);
            }
        });
    }
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JPanel controlPanel;
    private javax.swing.JButton deleteSplineButton;
    private DrawPanel drawPanel;
    private javax.swing.JButton editSpline;
    private javax.swing.JButton newSplineButton;
    // End of variables declaration//GEN-END:variables
    
}
