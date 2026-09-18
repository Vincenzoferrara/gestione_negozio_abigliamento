import React from "react";
import {
  Box,
  Button,
  Typography,
  IconButton,
  Popover,
  TextField,
  InputAdornment,
} from "@mui/material";
import FilterAltIcon from '@mui/icons-material/FilterAlt';
import SearchIcon from '@mui/icons-material/Search';
import { __ } from "@wordpress/i18n";

const searchFieldSx = {
  width: { xs: "100%", sm: 200 },
  minWidth: 160,
  flexShrink: 0,
  "& .MuiOutlinedInput-root": {
    height: "36px !important",
    minHeight: "36px !important",
    paddingLeft: "8px !important",
    paddingRight: "8px !important",
    borderRadius: "6px !important",
    backgroundColor: "#FFFFFF !important",
    fontSize: "14px !important",
    boxShadow: "none !important",
  },
  "& .MuiOutlinedInput-notchedOutline": {
    border: "1px solid #E0E0E0 !important",
    borderRadius: "6px !important",
  },
  "& .MuiOutlinedInput-root:hover .MuiOutlinedInput-notchedOutline": {
    border: "1px solid #CFCFCF !important",
  },
  "& .MuiOutlinedInput-root.Mui-focused .MuiOutlinedInput-notchedOutline": {
    border: "1px solid #8B5DFF !important",
    borderWidth: "1px !important",
  },
  "& .MuiInputAdornment-root": {
    marginRight: "4px !important",
    border: "none !important",
    background: "transparent !important",
    boxShadow: "none !important",
  },
  "& .MuiInputAdornment-root .MuiSvgIcon-root": {
    fontSize: "18px !important",
    color: "#9698C2 !important",
  },
  "& .MuiOutlinedInput-input": {
    padding: "8px 4px !important",
    height: "auto !important",
    lineHeight: "1.4 !important",
    fontSize: "14px !important",
    boxShadow: "none !important",
    border: "none !important",
    background: "transparent !important",
  },
};

const FilterSection = ({
  categories,
  selectedCategory,
  handleCategoryChange,
  anchorEl,
  handleFilterClick,
  handleCloseFilter,
  handleFilterChange,
  selectedType,
  openFilter,
  searchTerm,
  handleSearchData,
}) => {
  return (
    <Box
      sx={{
        border: "1px solid #E0E0E0",
        borderRadius: "8px",
        padding: 2,
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        marginBottom: 2,
        flexWrap: "wrap",
        gap: 1,
      }}
    >
      {/* Left: Categories */}
      <Box
        sx={{
          display: "flex",
          gap: 1,
          overflowX: "auto",
          flex: "1 1 auto",
          minWidth: 0,
        }}
      >
        {categories.map((category) => (
          <Button
            key={category}
            onClick={() => handleCategoryChange(category)}
            sx={{
              border: "none",
              fontSize: "14px",
              fontWeight: "500",
              backgroundColor:
                selectedCategory === category ? "#EBE4FF" : "#FFFFFF",
              color: selectedCategory === category ? "#7C54F1" : "#9698C2",
              whiteSpace: "nowrap",
              flexShrink: 0,
            }}
            variant="outlined"
          >
            {category}
          </Button>
        ))}
      </Box>

      {/* Right: Search + Sort by */}
      <Box sx={{ display: "flex", alignItems: "center", gap: 1, flexShrink: 0 }}>
        <TextField
          size="small"
          variant="outlined"
          placeholder={__( 'Search', 'mycred' )}
          value={searchTerm}
          onChange={handleSearchData}
          sx={searchFieldSx}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
        />

        <Typography variant="body2" fontWeight={500} color="text.secondary">
          {__( 'Sort by', 'mycred' )}
        </Typography>
        <IconButton onClick={handleFilterClick}>
          <FilterAltIcon />
        </IconButton>
        <Popover
          open={openFilter}
          anchorEl={anchorEl}
          onClose={handleCloseFilter}
          anchorOrigin={{
            vertical: "bottom",
            horizontal: "right",
          }}
          transformOrigin={{
            vertical: "top",
            horizontal: "right",
          }}
          disableScrollLock={true}
          sx={{
            '& .MuiPopover-paper': {
              boxShadow: '0 4px 20px rgba(0, 0, 0, 0.15)',
              border: '1px solid #E0E0E0',
              borderRadius: '8px',
            }
          }}
        >
          <Box
            sx={{
              padding: 2,
              display: "flex",
              flexDirection: "column",
              gap: 1.5,
              minWidth: 180,
            }}
          >
            <Typography variant="subtitle2" fontWeight="bold">
              {__( 'Filter', 'mycred' )}
            </Typography>
            <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("all");
                }}
                sx={{
                  color: selectedType === "all" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "all" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'All', 'mycred' )}
              </Typography>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("builtin");
                }}
                sx={{
                  color: selectedType === "builtin" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "builtin" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'Built-in Add-ons', 'mycred' )}
              </Typography>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("free");
                }}
                sx={{
                  color: selectedType === "free" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "free" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'Free Add-ons', 'mycred' )}
              </Typography>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("pro");
                }}
                sx={{
                  color: selectedType === "pro" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "pro" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'Pro Add-ons', 'mycred' )}
              </Typography>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("active");
                }}
                sx={{
                  color: selectedType === "active" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "active" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'Active Add-ons', 'mycred' )}
              </Typography>
              <Typography
                variant="caption"
                sx={{ color: "text.secondary", fontWeight: 600, mt: 1 }}
              >
                {__( 'Toolkit Pro Plans', 'mycred' )}
              </Typography>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("basic");
                }}
                sx={{
                  color: selectedType === "basic" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "basic" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'Basic Plan', 'mycred' )}
              </Typography>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("professional");
                }}
                sx={{
                  color: selectedType === "professional" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "professional" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'Professional Plan', 'mycred' )}
              </Typography>
              <Typography
                component="a"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleFilterChange("business");
                }}
                sx={{
                  color: selectedType === "business" ? "primary.main" : "text.primary",
                  textDecoration: "none",
                  fontWeight: selectedType === "business" ? "bold" : "normal",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                {__( 'Business Plan', 'mycred' )}
              </Typography>
            </Box>
          </Box>
        </Popover>
      </Box>
    </Box>
  );
};

export default FilterSection;
