document.addEventListener("DOMContentLoaded", () => {
    const categoryList = document.getElementById("category-list");
    const positionList = document.getElementById("position-list");
    const closeBtn = document.getElementById("close-btn");
    const tablet = document.getElementById("tablet");
    const currentCategory = document.getElementById("current-category");

    window.addEventListener("message", (event) => {
      const data = event.data;
      if (data.type === "updateLocations") {
        populateCategories(data.locations);
        showTablet();
      }
    });

    closeBtn.addEventListener("click", () => {
      fetch(`https://${GetParentResourceName()}/closeTablet`, {
        method: "POST",
      }).then(() => {
        hideTablet();
      });
    });
  
    function populateCategories(locations) {
        if (!Array.isArray(locations) || locations.length === 0) {
            console.warn("No locations available");
            categoryList.innerHTML = "<li>No locations available</li>";
            return;
        }
    
        categoryList.innerHTML = "";
        positionList.innerHTML = ""; 
        currentCategory.textContent = "Select a Category";
    
        locations.forEach((location) => {
            const li = document.createElement("li");
            li.textContent = location.name;
            li.addEventListener("click", () => {
                currentCategory.textContent = location.name;
                populatePositions(location.cctv); 
            });
            categoryList.appendChild(li);
        });
    }
    
    function populatePositions(cctvLocations) {
        if (!Array.isArray(cctvLocations) || cctvLocations.length === 0) {
            console.warn("No positions available for the selected category");
            positionList.innerHTML = "<li>No positions available</li>";
            return;
        }
    
        positionList.innerHTML = "";
        cctvLocations.forEach((camera) => {
            const li = document.createElement("li");
            li.textContent = camera.info;
            li.addEventListener("click", () => {
                fetch(`https://${GetParentResourceName()}/selectPosition`, {
                    method: "POST",
                    body: JSON.stringify({ pos: camera.pos, info: camera.info }),
                }).then(() => {
                    hideTablet(); 
                    SetNuiFocus(false, false); 
                }).catch((error) => {
                });
            });
            positionList.appendChild(li);
        });
    }    
  
    function selectPosition(pos, info) {
        console.log("Sending selected position to Lua:", pos, info);
    
        fetch(`https://${GetParentResourceName()}/selectPosition`, {
            method: "POST",
            body: JSON.stringify({ pos: pos, info: info }),
            headers: { "Content-Type": "application/json" },
        })
            .then((response) => response.json())
            .then((data) => {
                console.log("Response from Lua:", data);
            })
            .catch((error) => {
                console.error("Error selecting position:", error);
            });
    }    

    function showTablet() {
      tablet.classList.remove("hidden");
      tablet.classList.add("visible");
    }

    function hideTablet() {
      tablet.classList.remove("visible");
      tablet.classList.add("hidden");
    }
  });
  
