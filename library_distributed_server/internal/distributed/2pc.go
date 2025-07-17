package distributed

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// HandleTransferBook2PC - Simulate distributed book transfer using 2PC
func HandleTransferBook2PC(c *gin.Context) {
	// 1. Receive transfer request: {MaQuyenSach, FromMaCN, ToMaCN}
	var req struct {
		MaQuyenSach string `json:"maQuyenSach"`
		FromMaCN    string `json:"fromMaCN"`
		ToMaCN      string `json:"toMaCN"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// 2. Phase 1: Prepare (ask both sites to lock/update)
	// 3. Phase 2: Commit (update both sites)
	// For demo, just return success
	c.JSON(http.StatusOK, gin.H{"message": "2PC simulated for book transfer", "data": req})
}
